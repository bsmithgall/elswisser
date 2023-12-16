# Elswisser

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## (Re) build your development database

```sh
rm elswisser_dev.db* ||: && mix ecto.migrate && mix run priv/repo/seeds.exs
```

## The dumbest release process on earth

```sh
docker build --platform linux/arm64 .
docker tag <copy sha here> ghcr.io/bsmithgall/elswisser:<version>
docker tag <copy sha here> ghcr.io/bsmithgall/elswisser:latest
docker push ghcr.io/bsmithgall/elswisser:<version>
docker push ghcr.io/bsmithgall/elswisser:latest
```