# ============================================================
# PATH — static (no subprocess for brew shellenv)
# ============================================================
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/Users/kobig/.bun/bin:/Users/kobig/.local/bin:/Users/kobig/.claude-code-templates/bin:/Users/kobig/.antigravity/antigravity/bin:$PATH"

# ============================================================
# Oh My Zsh
# ============================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_DISABLE_COMPFIX=true    # skip compaudit security check (saves ~30ms)
fpath=(/Users/kobig/.docker/completions $fpath)  # must be before source omz
plugins=(git git-flow docker docker-compose history sudo extract command-not-found fzf-tab)
source $ZSH/oh-my-zsh.sh   # calls compinit once internally

# ============================================================
# Locale & Editor
# ============================================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR='vim'

# ============================================================
# History
# ============================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS       # skip consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries
setopt HIST_IGNORE_SPACE      # don't record entries starting with space
setopt HIST_VERIFY            # show command before executing from history expansion
setopt SHARE_HISTORY          # share history across sessions
setopt EXTENDED_HISTORY       # save timestamp + duration

# ============================================================
# zsh options
# ============================================================
setopt AUTO_CD                # type dir name to cd
setopt CORRECT                # spell correction for commands
setopt GLOB_DOTS              # include dotfiles in globs (ls *, tab complete)
setopt NO_BEEP                # no beep on error
setopt INTERACTIVE_COMMENTS   # allow # comments in interactive shell

# ============================================================
# NVM (lazy load — shaves ~300-500ms off startup)
# ============================================================
export NVM_DIR="$HOME/.nvm"
nvm() {
  unfunction nvm
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
  nvm "$@"
}

# ============================================================
# Shell enhancements
# ============================================================
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-autopair/autopair.zsh

# ============================================================
# Tool initializers — cached (regenerate only when binary changes)
# ============================================================
_evalcache() {
  local cache="${HOME}/.cache/zsh/evalcache/${1##*/}.${*// /_}.zsh"
  local bin
  bin="$(command -v "$1" 2>/dev/null)" || return 1
  if [[ ! -s "$cache" || "$bin" -nt "$cache" ]]; then
    mkdir -p "${cache%/*}"
    "$@" > "$cache"
  fi
  source "$cache"
}

_evalcache zoxide init zsh
_evalcache fzf --zsh
_evalcache direnv hook zsh
_evalcache atuin init zsh
_evalcache starship init zsh

# ============================================================
# Completion styling (fzf-tab + zstyle)
# ============================================================
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'        # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"           # colored completions
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'

# fzf-tab: preview for cd and files
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always $realpath'
zstyle ':fzf-tab:complete:*' fzf-preview 'bat --color=always --line-range :50 $realpath 2>/dev/null || eza --color=always $realpath 2>/dev/null'

# ============================================================
# Aliases — general
# ============================================================
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias bf='brew update && brew outdated && brew upgrade && brew upgrade --cask --greedy && brew cleanup -s'

# safety: send to trash instead of permanent delete
alias rm='trash'

# eza (replaces ls)
alias ls='eza'
alias ll='eza -la --git --icons'
alias lt='eza --tree --level=3 --git-ignore'

# bat (replaces cat)
alias cat='bat'

# shortcuts
alias g='git'
alias d='docker'

# ============================================================
# Aliases — Git
# ============================================================
alias glog='git log --oneline --graph --decorate --all'
alias gcm='git checkout main && git pull'
alias gclean='git branch --merged | grep -v "main\|master\|\*" | xargs git branch -d'

# ============================================================
# Aliases — Docker
# ============================================================
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dclean='docker system prune -af --volumes'
alias dlogs='docker logs -f'

# ============================================================
# Aliases — Bun / Node
# ============================================================
alias bi='bun install'
alias br='bun run'
alias brd='bun run dev'
alias brt='bun run test'
alias ace='node ace'

# ============================================================
# Aliases — Claude Code
# ============================================================
alias c='claude'
alias csp='claude --dangerously-skip-permissions'
alias cspr='claude --dangerously-skip-permissions --resume'
alias cmcpl='claude mcp list'
alias cmcpa='claude mcp add'
alias cmcpr='claude mcp remove'
alias cmcpad='claude mcp add-from-claude-desktop'
alias cdoc='claude doctor'
alias cinit='claude init'

alias claude-mem='bun "/Users/kobig/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Claude Code: increase skill description budget
export SLASH_COMMAND_TOOL_CHAR_BUDGET=20000

# ============================================================
# Functions
# ============================================================
mkcd() { mkdir -p "$1" && cd "$1" }

dsh() { docker exec -it "$1" /bin/sh }

uninstall() {
  local app="$1"
  if [ -z "$app" ]; then
    echo "Usage: uninstall <package_name>"
    return 1
  fi
  echo "==> Uninstalling with zap: $app"
  brew uninstall --zap "$app"
  echo "==> Deleting related files from ~/Library..."
  find ~/Library -iname "*$app*" -exec echo "Deleting: {}" \; -exec rm -rf {} \;
  echo "Done: all matched files for '$app' deleted."
}

# ============================================================
# Keybindings
# ============================================================
bindkey -e                        # emacs mode (Ctrl+A/E, Ctrl+U, etc.)
bindkey '^X^E' edit-command-line  # open current command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line

# ============================================================
# Shell integrations
# ============================================================
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# bun completions
[ -s "/Users/kobig/.bun/_bun" ] && source "/Users/kobig/.bun/_bun"
