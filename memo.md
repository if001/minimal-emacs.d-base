
## treesit
```
treesit-install-language-grammar
```

## LSP
### lsp-booster
```
cargo install emacs-lsp-booster
```

### gopls

```
go install golang.org/x/tools/gopls@latest
```


### python
```
pip install pyright
```


project_rootにpyrightconfig.jsonを置く
```
{
  "venvPath": ".",
  "venv": ".venv",
  "exclude": [
    ".venv"
  ]
}
```


## mcp
```
go install github.com/isaacphi/mcp-language-server@latest
```

### firecrawl-mcp
```
git clone https://github.com/firecrawl/firecrawl-mcp-server.git
npm run build
```
