# Generisanje novog ključa (samo lupaj ENTER na svako pitanje)
ssh-keygen -t ed25519 -C "tvoj_email@primer.com"

# Pokretanje SSH agenta (Fish sintaksa)
eval (ssh-agent -c)

# Dodavanje ključa u agenta
ssh-add ~/.ssh/id_ed25519

# Ispisivanje javnog ključa i kopiranje ga:
cat ~/.ssh/id_ed25519.pub

Akcija: GitHub Settings -> SSH keys.
New SSH key.
Nalepiti ključ i sačuvati.

Postaviti svoj identitet (moraš biti isti kao na GitHub-u):
git config --global user.name "tvpj_user_name"
git config --global user.email "tvoj_email@primer.com"

# Ako je projekat (npr. dotfiles) već kloniran preko HTTPS-a, promeniti ga:
 Proveriti trenutni link
git remote -v

 Prebaci na SSH (zameni "dotfiles" imenom svog repoa ako je drugačiji)
git remote set-url origin git@github.com:linuxdeda/dotfiles.git

# Da bi SSH agent radio stalno, dodati ovo u ~/.config/fish/config.fish:
 SSH Agent trajno pokretanje
 
if not pgrep -u $USER ssh-agent > /dev/null
    ssh-agent -c > $XDG_RUNTIME_DIR/ssh-agent.fish
end
source $XDG_RUNTIME_DIR/ssh-agent.fish > /dev/null

# Brzi aliasi za rad
alias gsave='git add .; and git commit -m "Update"; and git push'

# Testirati konekciju
ssh -T git@github.com

# Git Workflow
```bash
git add .
git commit -m "Sređen SSH i Git setup"
git push

Nix je napravio symlink koji je "read-only". Obriši ga:

```bash
rm ~/.config/git/config

Sada napravi novi, običan tekstualni fajl na istom mestu:

```bash
nano ~/.config/git/config

```bash
[user]
name = linuxdeda
email = linuxdeda@gmail.com

