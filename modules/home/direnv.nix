# direnv configuration
{...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;

    stdlib = ''
      use_flake() {
        watch_file flake.nix
        watch_file flake.lock
        eval "$(nix print-dev-env --profile "$(direnv_layout_dir)/flake-profile")"
      }

      layout_python() {
        local python="''${1:-python3}"
        [[ $# -gt 0 ]] && shift
        unset PYTHONHOME
        if [[ -n $VIRTUAL_ENV ]]; then
          VIRTUAL_ENV=$(realpath "''${VIRTUAL_ENV}")
        else
          local python_version
          python_version=$($python -c "import platform; print(platform.python_version())")
          if [[ -z $python_version ]]; then
            log_error "Could not detect Python version"
            return 1
          fi
          VIRTUAL_ENV=$PWD/.direnv/python-$python_version
        fi
        export VIRTUAL_ENV
        if [[ ! -d $VIRTUAL_ENV ]]; then
          log_status "Creating virtual environment..."
          $python -m venv "$VIRTUAL_ENV"
        fi
        PATH_add "$VIRTUAL_ENV/bin"
      }

      use_node() {
        local node_version=$1
        local node_modules_dir="$PWD/node_modules"

        if [[ -n $node_version ]]; then
          log_status "Using Node.js version $node_version"
        elif [[ -f .nvmrc ]]; then
          node_version=$(cat .nvmrc)
          log_status "Using Node.js version $node_version from .nvmrc"
        fi

        if [[ -d $node_modules_dir ]]; then
          PATH_add "$node_modules_dir/.bin"
        fi
      }

      layout_go() {
        export GOPATH="$PWD/.direnv/go"
        PATH_add "$GOPATH/bin"
        mkdir -p "$GOPATH/src"
      }

      layout_ruby() {
        if [[ -f .ruby-version ]]; then
          local ruby_version=$(cat .ruby-version)
          log_status "Using Ruby version $ruby_version"
        fi
        export GEM_HOME="$PWD/.direnv/ruby/gems"
        export GEM_PATH="$GEM_HOME"
        PATH_add "$GEM_HOME/bin"
      }

      load_secrets() {
        if [[ -f .env.secrets ]]; then
          log_status "Loading secrets from .env.secrets"
          set -a
          source .env.secrets
          set +a
        fi
      }

      dotenv() {
        local env_files=("$@")
        if [[ ''${#env_files[@]} -eq 0 ]]; then
          env_files=(.env)
        fi
        for env_file in "''${env_files[@]}"; do
          if [[ -f $env_file ]]; then
            log_status "Loading env from $env_file"
            set -a
            source "$env_file"
            set +a
          fi
        done
      }
    '';
  };
}
