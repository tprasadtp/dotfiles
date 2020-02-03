" Specify a directory for plugins
call plug#begin('~/.cache/plugged')

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins :: Workflow Tools
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Highlight whitespace
Plug 'ntpeters/vim-better-whitespace'

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin', { 'on':  'NERDTreeToggle' }

" Fugitive
Plug 'tpope/vim-fugitive'

" endwise to auto end in bash, ruby, jinja etc
Plug 'tpope/vim-endwise'

" Indentation
Plug 'Yggdroot/indentLine'

" fzf
Plug 'junegunn/fzf'

" editorconfig
Plug 'editorconfig/editorconfig-vim'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins :: Fancy
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Plug 'ryanoasis/vim-devicons'
Plug 'arcticicestudio/nord-vim'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins :: Language Tools
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'scrooloose/syntastic'

" Rust
Plug 'rust-lang/rust.vim'


" => Hashicorp
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'fatih/vim-hclfmt'
Plug 'hashivim/vim-terraform'
Plug 'hashivim/vim-vaultproject'
Plug 'hashivim/vim-consul'
Plug 'hashivim/vim-nomadproject'
Plug 'hashivim/vim-packer'

" JOSN
Plug 'elzr/vim-json'

" Ansible
Plug 'pearofducks/ansible-vim'

" Go

" Markdown
Plug 'godlygeek/tabular'
Plug 'tpope/vim-markdown'

" TOML
Plug 'cespare/vim-toml'

" YAML
Plug 'stephpy/vim-yaml'

" Octave
Plug 'jvirtanen/vim-octave'

" LateX
Plug 'lervag/vimtex'


" autocomplete all
Plug 'valloric/youcompleteme'

"Dockerfile
Plug 'ekalinin/dockerfile.vim'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins :: Themes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins :: sysadmin
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Nginx Config
Plug 'chr4/nginx.vim'

" systemd language syntax
Plug 'wgwoods/vim-systemd-syntax'

" Initialize plugin system
call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => User Interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Searching
set ignorecase " case insensitive searching
set smartcase " case-sensitive if expresson contains a capital letter
set hlsearch
set incsearch " set incremental search, like modern browsers
set nolazyredraw " don't redraw while executing macros

set magic " Set magic on, for regex

set showmatch " show matching braces
set mat=2 " how many tenths of a second to blink

" switch syntax highlighting on
syntax on

set encoding=utf8
let base16colorspace=256  " Access colors present in 256 colorspace"
set t_Co=256 " Explicitly tell vim that the terminal supports 256 colors"
set background=dark
colorscheme delek

set number

set autoindent " automatically set indent of new line
set smartindent

set laststatus=2 " show the satus line all the time

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map <leader>ev :e! ~/.vimrc<cr> " edit ~/.vimrc

map <leader>wc :wincmd q<cr>

" moving up and down work as you would expect
nnoremap <silent> j gj
nnoremap <silent> k gk

" helpers for dealing with other people's code
nmap \t :set ts=4 sts=4 sw=4 noet<cr>
nmap \s :set ts=4 sts=4 sw=4 et<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" close NERDTree after a file is opened
let g:NERDTreeQuitOnOpen=1
" show hidden files in NERDTree
let NERDTreeShowHidden=1
" Toggle NERDTree
nmap <silent> <leader>n :NERDTreeToggle<cr>
" expand to the path of the file in the current buffer
nmap <silent> <leader>y :NERDTreeFind<cr>

let g:airline#extensions#tabline#enabled = 1
