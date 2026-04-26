# Doggo

## Quick Start (Docker Compose)

The easiest way to get started is using Docker Compose, which includes both the Phoenix development environment and PostgreSQL database.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Docker Compose (included with Docker Desktop)
- VSCode or Cursor with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) (optional, for integrated editor support)

### Start the Development Environment

```bash
# Start the containers (Phoenix app + PostgreSQL)
make dc.up

# Enter the development container
make dc.shell

# Inside the container, run setup and start the server
mix setup
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Available Make Commands

| Command | Description |
|---------|-------------|
| `make dc.up` | Start the devcontainer and PostgreSQL |
| `make dc.stop` | Stop containers (keeps data) |
| `make dc.down` | Stop and remove containers (wipes data) |
| `make dc.rebuild` | Rebuild and restart containers |
| `make dc.shell` | Open a shell inside the app container |
| `make dc.deps` | Fetch Hex dependencies (run after `git pull` when `mix.lock` changed) |
| `make dc.logs` | View container logs |
| `make list` | Show all available commands |

### Development Workflow

After the initial setup, your daily workflow is:

```bash
# Terminal 1: Start containers
make dc.up

# Terminal 2: Enter container and start Phoenix
make dc.shell
mix phx.server
```

The database data persists in a Docker volume across container restarts.

After you pull changes that update `mix.lock`, run `make dc.deps` (with containers up) so Hex dependencies are installed into the devcontainer’s `deps/devcontainer` path; rebuilding the image alone does not fetch new packages.

### Using VSCode/Cursor (Alternative)

If you prefer an integrated IDE experience instead of the terminal:

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) in VSCode/Cursor
2. Open the project folder in VSCode/Cursor
3. Click the prompt to "Reopen in Container" (or use Command Palette: `Dev Containers: Reopen in Container`)
4. The editor will automatically:
   - Build and start the containers
   - Install recommended extensions (ElixirLS, Tailwind CSS, etc.)
   - Forward ports 4000 (Phoenix) and 5432 (PostgreSQL)
   - Set up the terminal and formatting

Once loaded, open a terminal in VSCode/Cursor and run `mix setup && mix phx.server`.

### Troubleshooting

**Port 4000 already in use:**
```bash
docker stop $(docker ps -q)
docker-compose up -d
```

**Database connection errors:**
Ensure the database container is running: `docker ps` should show `doggo-db`

**Missing or outdated Hex dependencies** (e.g. “dependency is not available” or errors right after `git pull`):
With containers running, run `make dc.deps`. Do not run `mix deps.get` on the host without the same `MIX_DEPS_PATH` the container uses, or the app in Docker will still be missing packages.

**Rebuild from scratch:**
```bash
make dc.down
make dc.up
make dc.shell
mix setup
```

---

## Manual Setup (Without Docker)

If you prefer not to use Docker:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
* Visit [`localhost:4000`](http://localhost:4000)

You'll need PostgreSQL running locally with:
- Database: `doggo_dev`
- Username: `postgres`
- Password: `postgres`
- Host: `localhost:5432`

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
