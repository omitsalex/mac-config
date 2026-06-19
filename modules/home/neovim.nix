# Neovim configuration
{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # This config drives completion through CoC (node-based), not the Python/Ruby
    # remote providers. Disable them explicitly to silence the home-manager
    # default-change eval warnings and slim the build.
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      gruvbox
      vim-airline
      vim-airline-themes
      vim-devicons

      nerdtree
      fzf-vim

      vim-polyglot
      auto-pairs
      nerdcommenter
      vim-surround

      coc-nvim
      coc-json
      coc-pyright

      vim-fugitive
      vim-gitgutter
    ];

    extraConfig = ''
      " Options
      set clipboard=unnamedplus
      set completeopt=noinsert,menuone,noselect
      set cursorline
      set hidden
      set autoindent
      set inccommand=split
      set mouse=a
      set number relativenumber
      set splitbelow splitright
      set title
      set wildmenu
      set cc=80
      filetype plugin indent on
      syntax on
      set spell
      set ttyfast

      set nocompatible
      set linebreak
      set showbreak=+++
      set textwidth=100
      set showmatch
      set visualbell

      set hlsearch
      set smartcase
      set ignorecase
      set incsearch

      set expandtab
      set shiftwidth=2
      set smartindent
      set smarttab
      set softtabstop=2

      set ruler
      set undolevels=1000
      set backspace=indent,eol,start

      set termguicolors
      hi Cursor guifg=green guibg=green
      hi Cursor2 guifg=red guibg=red
      set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50

      colorscheme gruvbox
      set background=dark

      let g:bargreybars_auto=0
      let g:airline_solorized_bg='dark'
      let g:airline_powerline_fonts=1
      let g:airline_theme='gruvbox'
      let g:airline#extension#tabline#enable=1
      let g:airline#extension#tabline#left_sep=' '
      let g:airline#extension#tabline#left_alt_sep='|'
      let g:airline#extension#tabline#formatter='unique_tail'

      map <C-n> :NERDTreeToggle<CR>
      let NERDTreeShowHidden=1
      let NERDTreeQuitOnOpen=1

      nnoremap <C-p> :Files<CR>
      nnoremap <C-g> :Rg<CR>

      " Coc.nvim
      let g:coc_global_extensions = ['coc-tsserver']
      let g:coc_node_path = '${pkgs.nodejs}/bin/node'
      let g:coc_node_args = ['--max-old-space-size=4096']
      set nobackup
      set nowritebackup
      set cmdheight=2
      set updatetime=300
      set shortmess+=c
      set signcolumn=yes

      inoremap <silent><expr> <TAB>
            \ pumvisible() ? "\<C-n>" :
            \ <SID>check_back_space() ? "\<TAB>" :
            \ coc#refresh()
      inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

      function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~# '\s'
      endfunction

      inoremap <silent><expr> <c-space> coc#refresh()
      inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                                    \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

      nmap <silent> gd <Plug>(coc-definition)
      nmap <silent> gy <Plug>(coc-type-definition)
      nmap <silent> gi <Plug>(coc-implementation)
      nmap <silent> gr <Plug>(coc-references)

      let mapleader = " "
      nmap <leader>w :w!<cr>
      nmap <leader>q :q<cr>
      nmap <leader>wq :wq<cr>

      nnoremap <C-J> <C-W><C-J>
      nnoremap <C-K> <C-W><C-K>
      nnoremap <C-L> <C-W><C-L>
      nnoremap <C-H> <C-W><C-H>
    '';
  };
}
