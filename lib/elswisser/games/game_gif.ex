defmodule Elswisser.Games.GameGif do
  use Rustler, otp_app: :elswisser, crate: :to_gif

  def encode(_fens, _delay_cs), do: :erlang.nif_error(:nif_not_loaded)
end
