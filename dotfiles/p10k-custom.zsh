# p10k-custom.zsh - Custom Powerlevel10k settings overlay
# This file only contains your personal customizations to be loaded after the main p10k config

# Set the prompt style to use nerdfont-complete icons
typeset -g POWERLEVEL9K_MODE=nerdfont-complete

# Custom left prompt elements
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  # =========================[ Line #1 ]=========================
  os_icon                 # os identifier
  dir                     # current directory
  vcs                     # git status
  # =========================[ Line #2 ]=========================
  newline                 # \n
  prompt_char             # prompt symbol
)

# Custom right prompt elements
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  # =========================[ Line #1 ]=========================
  status                  # exit code of the last command
  command_execution_time  # duration of the last command
  background_jobs         # presence of background jobs
  aws                     # AWS profile
  kubecontext             # Kubernetes context
  terraform_version     # terraform version (https://www.terraform.io)
  time                    # current time
  # =========================[ Line #2 ]=========================
  newline
  public_ip             # public IP address
  wifi                  # wifi speed
)

# Custom styling for command char (green for success, red for error)
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196

# Directory settings with colored background
typeset -g POWERLEVEL9K_DIR_BACKGROUND=4
typeset -g POWERLEVEL9K_DIR_FOREGROUND=254
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=250
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=255

# VCS (git) settings with colored backgrounds
typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=3
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=2
typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=3
typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND=8
typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '

# Status indicator settings
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=2
typeset -g POWERLEVEL9K_STATUS_OK_BACKGROUND=0
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=2
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_BACKGROUND=0
typeset -g POWERLEVEL9K_STATUS_ERROR=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=3
typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=1
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=3
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_BACKGROUND=1
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=3
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_BACKGROUND=1

# Command execution time styling
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=0
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=3

# Background jobs styling
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=6
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=0

# Time display styling
typeset -g POWERLEVEL9K_TIME_FOREGROUND=0
typeset -g POWERLEVEL9K_TIME_BACKGROUND=7

# Visual indicators for prompt line
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=244

# Rainbow style with no boxed prompt
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

# Disable instant prompt (as per your original configuration)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Styling for AWS segment
typeset -g POWERLEVEL9K_AWS_BACKGROUND=208 # Orange background
typeset -g POWERLEVEL9K_AWS_FOREGROUND=0   # Black text

# Styling for Kubernetes context
typeset -g POWERLEVEL9K_KUBECONTEXT_BACKGROUND=26  # Blue background
typeset -g POWERLEVEL9K_KUBECONTEXT_FOREGROUND=255 # White text
# Shorten the context display (e.g., gke_project_zone_name -> gke:name)
typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|kogito'
# Show only cluster name, not the full context
typeset -g POWERLEVEL9K_KUBECONTEXT_CONTENT_EXPANSION='${P9K_KUBECONTEXT_CLUSTER}'

# Styling for Terraform version
typeset -g POWERLEVEL9K_TERRAFORM_VERSION_BACKGROUND=105  # Purple background
typeset -g POWERLEVEL9K_TERRAFORM_VERSION_FOREGROUND=255  # White text
# Only show Terraform version after running terraform or tf commands
typeset -g POWERLEVEL9K_TERRAFORM_VERSION_SHOW_ON_COMMAND='terraform|tf|terragrunt|tg|tfp|tfa'

# Styling for Public IP
typeset -g POWERLEVEL9K_PUBLIC_IP_BACKGROUND=3  # Yellow background
typeset -g POWERLEVEL9K_PUBLIC_IP_FOREGROUND=0  # Black text
# Only show public IP when running ip-related commands
typeset -g POWERLEVEL9K_PUBLIC_IP_SHOW_ON_COMMAND='ip|curl|wget|dig|host|nslookup|ping|traceroute|whois'

# Styling for WiFi
typeset -g POWERLEVEL9K_WIFI_BACKGROUND=5  # Magenta background
typeset -g POWERLEVEL9K_WIFI_FOREGROUND=0  # Black text
# Only show WiFi information when running network-related commands
typeset -g POWERLEVEL9K_WIFI_SHOW_ON_COMMAND='ping|curl|wget|ssh|nc|netstat|dig|host|nslookup|networksetup|airport|speedtest|fast'

# Disable hot reload for better performance
typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
