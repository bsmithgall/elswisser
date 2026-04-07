fn main() {
    let contents = std::fs::read_to_string("./test_fens.txt").unwrap();
    let fens: Vec<String> = contents.lines().map(String::from).collect();

    let start = std::time::Instant::now();
    let gif = to_gif::encode_gif(fens, 70).unwrap();
    let elapsed = start.elapsed();
    std::fs::write("out.gif", &gif).unwrap();
    println!("Wrote out.gif ({} bytes) in {:?}", gif.len(), elapsed);
}
