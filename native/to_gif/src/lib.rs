use std::borrow::Cow;
use std::sync::LazyLock;

use image::{self, RgbaImage};

const SQUARE_SIZE: u32 = 60;
const QUANTIZER_SPEED: i32 = 10;

// Derived from tailwind board color configuration
const COLOR_LIGHT: image::Rgba<u8> = image::Rgba([0xf2, 0xf5, 0xf3, 255]);
const COLOR_DARK: image::Rgba<u8> = image::Rgba([0x71, 0x82, 0x8f, 255]);

macro_rules! sprites {
    ($($name:ident => $file:literal),+ $(,)?) => {
        $(
            static $name: LazyLock<RgbaImage> = LazyLock::new(|| {
                let bytes = include_bytes!(concat!("../sprites/", $file));
                image::load_from_memory(bytes).unwrap().into_rgba8()
            });
        )+
    };
}

sprites! {
    WHITE_PAWN   => "white_pawn.png",
    WHITE_ROOK   => "white_rook.png",
    WHITE_KNIGHT => "white_knight.png",
    WHITE_BISHOP => "white_bishop.png",
    WHITE_QUEEN  => "white_queen.png",
    WHITE_KING   => "white_king.png",
    BLACK_PAWN   => "black_pawn.png",
    BLACK_ROOK   => "black_rook.png",
    BLACK_KNIGHT => "black_knight.png",
    BLACK_BISHOP => "black_bishop.png",
    BLACK_QUEEN  => "black_queen.png",
    BLACK_KING   => "black_king.png",
}

// -- NIF entry point --

#[rustler::nif(schedule = "DirtyCpu")]
pub fn encode<'a>(env: rustler::Env<'a>, fens: Vec<String>, delay_cs: u16) -> Result<rustler::Binary<'a>, String> {
    let bytes = encode_gif(fens, delay_cs).map_err(|e| e.to_string())?;
    let mut binary = rustler::OwnedBinary::new(bytes.len())
        .ok_or_else(|| "failed to allocate binary for GIF output".to_string())?;
    binary.as_mut_slice().copy_from_slice(&bytes);
    Ok(binary.release(env))
}

// -- GIF encoding --

pub fn encode_gif(fens: Vec<String>, delay_cs: u16) -> Result<Vec<u8>, gif::EncodingError> {
    let mut buf = Vec::new();
    let board_w = (SQUARE_SIZE * 8) as u16;
    let board_h = (SQUARE_SIZE * 8) as u16;

    let frames: Vec<RgbaImage> = fens.iter().map(|fen| render_fen(fen)).collect();

    {
        let mut encoder = gif::Encoder::new(&mut buf, board_w, board_h, &[])?;
        encoder.set_repeat(gif::Repeat::Infinite)?;

        for (i, img) in frames.iter().enumerate() {
            if i == 0 {
                // First frame: full board
                let mut rgba = img.clone().into_raw();
                let mut frame =
                    gif::Frame::from_rgba_speed(board_w, board_h, &mut rgba, QUANTIZER_SPEED);
                frame.delay = delay_cs;
                frame.dispose = gif::DisposalMethod::Keep;
                encoder.write_frame(&frame)?;
            } else {
                let prev = &frames[i - 1];
                let (x0, y0, x1, y1) = diff_bounds(prev, img);

                if x0 > x1 || y0 > y1 {
                    // Frames are identical — emit a minimal transparent frame for the delay
                    let frame = gif::Frame {
                        width: 1,
                        height: 1,
                        delay: delay_cs,
                        dispose: gif::DisposalMethod::Keep,
                        transparent: Some(0),
                        palette: Some(vec![0, 0, 0]),
                        buffer: Cow::Owned(vec![0]),
                        ..gif::Frame::default()
                    };
                    encoder.write_frame(&frame)?;
                    continue;
                }

                // Snap to square boundaries for cleaner diffs
                let sx0 = (x0 / SQUARE_SIZE) * SQUARE_SIZE;
                let sy0 = (y0 / SQUARE_SIZE) * SQUARE_SIZE;
                let sx1 = ((x1 / SQUARE_SIZE) + 1) * SQUARE_SIZE;
                let sy1 = ((y1 / SQUARE_SIZE) + 1) * SQUARE_SIZE;

                let region_w = sx1 - sx0;
                let region_h = sy1 - sy0;

                let sub = image::imageops::crop_imm(img, sx0, sy0, region_w, region_h).to_image();
                let mut rgba = sub.into_raw();
                let mut frame = gif::Frame::from_rgba_speed(
                    region_w as u16,
                    region_h as u16,
                    &mut rgba,
                    QUANTIZER_SPEED,
                );
                frame.delay = delay_cs;
                frame.dispose = gif::DisposalMethod::Keep;
                frame.left = sx0 as u16;
                frame.top = sy0 as u16;
                encoder.write_frame(&frame)?;
            }
        }
    }

    Ok(buf)
}

// -- Frame differencing --

/// Find the bounding box of pixels that differ between two images.
/// Returns (x0, y0, x1, y1) inclusive. If identical, x0 > x1.
fn diff_bounds(a: &RgbaImage, b: &RgbaImage) -> (u32, u32, u32, u32) {
    let w = a.width();
    let mut x0 = w;
    let mut y0 = a.height();
    let mut x1 = 0u32;
    let mut y1 = 0u32;

    for (i, (pa, pb)) in a
        .as_raw()
        .chunks_exact(4)
        .zip(b.as_raw().chunks_exact(4))
        .enumerate()
    {
        if pa != pb {
            let x = (i as u32) % w;
            let y = (i as u32) / w;
            x0 = x0.min(x);
            y0 = y0.min(y);
            x1 = x1.max(x);
            y1 = y1.max(y);
        }
    }

    (x0, y0, x1, y1)
}

// -- Board rendering --

pub fn render_fen(fen: &str) -> RgbaImage {
    let mut img = RgbaImage::new(SQUARE_SIZE * 8, SQUARE_SIZE * 8);
    // FEN board section is always the first space-separated field
    let board = fen.split(' ').next().unwrap();

    for (rank, row) in board.split('/').enumerate() {
        let mut file: u32 = 0;

        for ch in row.chars() {
            if let Some(skip) = ch.to_digit(10) {
                for _ in 0..skip {
                    fill_square(&mut img, file, rank as u32);
                    file += 1;
                }
            } else {
                fill_square(&mut img, file, rank as u32);
                let x = (file * SQUARE_SIZE) as i64;
                let y = (rank as u32 * SQUARE_SIZE) as i64;
                image::imageops::overlay(&mut img, sprite_for(ch), x, y);
                file += 1;
            }
        }
    }

    img
}

fn fill_square(img: &mut RgbaImage, file: u32, rank: u32) {
    let color = if (file + rank).is_multiple_of(2) {
        COLOR_LIGHT
    } else {
        COLOR_DARK
    };

    let x0 = file * SQUARE_SIZE;
    let y0 = rank * SQUARE_SIZE;

    for dy in 0..SQUARE_SIZE {
        for dx in 0..SQUARE_SIZE {
            img.put_pixel(x0 + dx, y0 + dy, color);
        }
    }
}

fn sprite_for(ch: char) -> &'static RgbaImage {
    match ch {
        'P' => &WHITE_PAWN,
        'R' => &WHITE_ROOK,
        'N' => &WHITE_KNIGHT,
        'B' => &WHITE_BISHOP,
        'Q' => &WHITE_QUEEN,
        'K' => &WHITE_KING,
        'p' => &BLACK_PAWN,
        'r' => &BLACK_ROOK,
        'n' => &BLACK_KNIGHT,
        'b' => &BLACK_BISHOP,
        'q' => &BLACK_QUEEN,
        'k' => &BLACK_KING,
        _ => panic!("unknown piece: '{ch}'"),
    }
}

rustler::init!("Elixir.Elswisser.Games.GameGif");
