.PHONY: list dc.up dc.status dc.stop dc.rebuild dc.down dc.shell dc.deps dc.claude dc.tidewave dc.tidewave.bg dc.tidewave.stop dc.logs.proxy dc.server dc.test dc.worktree.new dc.worktree.list dc.worktree.remove

define require_devcontainer
	@if [ "$$DEVCONTAINER" != "true" ]; then echo "Error: This command must be run inside the devcontainer." >&2; exit 1; fi
endef

list:
	@printf "  %-22s  %s\n" \
		"make list"              "List all available commmands (you ran this)" \
		"" "" \
		"# Commands to run on your host machine" "" \
		"make dc.up"             "Start the devcontainer and PostgreSQL" \
		"make dc.status"         "Show container status" \
		"make dc.stop"           "Stop containers (keeps data)" \
		"make dc.rebuild"        "Rebuild and start containers" \
		"make dc.down"           "Stop and remove containers (wipes data)" \
		"make dc.shell"          "Open a shell inside the app container" \
		"make dc.deps"           "Fetch Hex deps (run after mix.lock changes, e.g. git pull)" \
		"make dc.logs"           "View all container logs" \
		"" "" \
		"# Commands to run inside the devcontainer" "" \
		"make dc.claude"         "Run Claude Code (with --dangerously-skip-permissions)" \
		"make dc.tidewave"       "Run Tidewave (exposed on localhost:9833)" \
		"make dc.tidewave.bg"    "Run Tidewave in the background" \
		"make dc.tidewave.stop"  "Stop background Tidewave" \
		"make dc.server"         "Starts the Phoenix server inside an IEx session" \
		"make dc.test"           "Runs the test suite using 'mix test'" \
		"make dc.logs.proxy"     "Print proxy logs" \
		"make dc.logs.tidewave"  "Print tidewave logs" \
		"" "" \
		"# Worktree commands (run inside the devcontainer)" "" \
		"make dc.worktree.new feature-x"      "Create worktree for branch feature-x (from HEAD)" \
		"make dc.worktree.new feature-x main" "Create worktree for branch feature-x (from main)" \
		"make dc.worktree.list"               "List all worktrees" \
		"make dc.worktree.remove x"           "Remove worktree x" \
		"wt feature-x"                        "Switch to git worktree feature-x" \
		"wt"                                  "Switch to main git worktree" \
		"" ""

dc.up:
	docker-compose up -d

dc.status:
	@docker-compose ps

dc.stop:
	docker-compose stop

dc.rebuild:
	docker-compose up -d --build

dc.down:
	docker-compose down -v

dc.shell:
	docker-compose exec app zsh

dc.deps:
	docker-compose exec app mix deps.get

dc.logs:
	docker-compose logs -f

dc.claude:
	$(require_devcontainer)
	exec claude --dangerously-skip-permissions

dc.tidewave:
	$(require_devcontainer)
	exec tidewave --allow-remote-access --allowed-origins http://localhost:9833

dc.tidewave.bg:
	@$(MAKE) dc.tidewave > /tmp/tidewave.log 2>&1 & echo "Tidewave started (pid $$!). Logs: /tmp/tidewave.log"

dc.tidewave.stop:
	$(require_devcontainer)
	@pkill -f tidewave && echo "Tidewave stopped" || echo "Tidewave is not running"

dc.logs.proxy:
	$(require_devcontainer)
	exec tail -f /var/log/squid/access.log

dc.logs.tidewave:
	$(require_devcontainer)
	exec tail -f /tmp/tidewave.log

dc.server:
	$(require_devcontainer)
	exec iex -S mix phx.server

dc.test:
	$(require_devcontainer)
	MIX_ENV=test mix test

# --- Worktree commands ---
# Usage: make dc.worktree.new <name> [base-branch]
# The extra args are consumed via MAKECMDGOALS so make doesn't treat them as targets.
dc.worktree.new:
	$(require_devcontainer)
	$(eval WT_NAME := $(word 2,$(MAKECMDGOALS)))
	$(eval WT_BASE := $(word 3,$(MAKECMDGOALS)))
	@if [ -z "$(WT_NAME)" ]; then echo "Usage: make dc.worktree.new <name> [base-branch]"; exit 1; fi
	@if [ -n "$(WT_BASE)" ]; then \
		git worktree add .worktrees/$(WT_NAME) -b $(WT_NAME) $(WT_BASE); \
	else \
		git worktree add .worktrees/$(WT_NAME) -b $(WT_NAME); \
	fi

dc.worktree.list:
	$(require_devcontainer)
	@git worktree list

# Usage: make dc.worktree.remove <name>
dc.worktree.remove:
	$(require_devcontainer)
	$(eval WT_NAME := $(word 2,$(MAKECMDGOALS)))
	@if [ -z "$(WT_NAME)" ]; then echo "Usage: make dc.worktree.remove <name>"; exit 1; fi
	git worktree remove .worktrees/$(WT_NAME)

# Catch positional args passed after worktree targets so make doesn't error
%:
	@:
