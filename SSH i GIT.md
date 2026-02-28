# SSH i Git Setup

## Generisanje ključa
ssh-keygen -t ed25519 -C "linuxdeda@gmail.com"


## SSH agent (Fish)
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519

## Public key
cat ~/.ssh/id_ed25519.pub

GitHub: Settings > SSH keys > New SSH key

## Git config
git config --global user.name "linuxdeda"
git config --global user.email "linuxdeda@gmail.com"

## HTTPS -> SSH
git remote set-url origin git@github.com:linuxdeda/dotfiles.git

## Fish config.fish
if not pgrep -u $USER ssh-agent > /dev/null
    ssh-agent -c > $XDG_RUNTIME_DIR/ssh-agent.fish
end
source $XDG_RUNTIME_DIR/ssh-agent.fish > /dev/null

ssh -T git@github.com

## Nix fix
rm ~/.config/git/config
