# Linux cheatsheet za početnike

Praktičan vodič za ljude koji prvi put kreću sa Linuxom. Fokus je na brzom snalaženju, osnovnim komandama i potezima koji odmah imaju smisla u svakodnevnom radu.[cite:3][cite:9]

## 1. Šta je Linux

Linux nije jedna jedina verzija sistema, već porodica distribucija koje dele isto jezgro i osnovnu filozofiju otvorenog koda.[cite:1][cite:8] Za početnike su najbitnije distribucije koje nude laku instalaciju, dobru hardversku podršku i mnogo dokumentacije.[cite:4][cite:9]

## 2. Šta prvo da izabereš

| Situacija | Preporuka | Zašto |
|---|---|---|
| Hoćeš najlakši prelaz sa Windowsa | Linux Mint | Interfejs je poznat i često se preporučuje početnicima.[cite:4][cite:9] |
| Hoćeš najviše tutorijala i podrške | Ubuntu | Ima veliku zajednicu i mnogo uputstava.[cite:3][cite:9] |
| Imaš slabiji ili stariji računar | Xubuntu ili Lubuntu | Lakša desktop okruženja bolje rade na skromnijem hardveru.[cite:9] |
| Hoćeš da testiraš bez rizika | Live USB ili virtuelna mašina | Možeš da probaš sistem bez brisanja postojećeg OS-a.[cite:3][cite:9] |

## 3. Pre instalacije

- Napravi rezervnu kopiju važnih fajlova pre bilo kakvog rada sa particijama.[cite:9]
- Proveri da li rade Wi‑Fi, zvuk, grafika i touchpad u live režimu.[cite:3][cite:9]
- Ako nisi siguran šta radiš, nemoj odmah da brišeš postojeći sistem; test u virtuelnoj mašini je sigurniji prvi korak.[cite:3][cite:9]

## 4. Osnovna instalacija

1. Preuzmi ISO sa zvaničnog sajta distribucije.[cite:9]
2. Napravi bootabilan USB alatkom kao što je Rufus, Balena Etcher ili sličan program.[cite:9]
3. Pokreni računar sa USB-a i izaberi live režim ili instalaciju.[cite:3][cite:9]
4. Tokom instalacije pažljivo proveri disk i particije koje biraš.[cite:9]
5. Posle prvog podizanja odmah uradi ažuriranje sistema.[cite:9]

## 5. Prve komande koje moraš da znaš

| Komanda | Šta radi | Primer |
|---|---|---|
| `pwd` | Prikazuje trenutni direktorijum | `pwd` |
| `ls` | Prikazuje sadržaj direktorijuma | `ls -la` |
| `cd` | Menja direktorijum | `cd Dokumenti` |
| `mkdir` | Pravi novi direktorijum | `mkdir test` |
| `cp` | Kopira fajl ili direktorijum | `cp fajl.txt backup.txt` |
| `mv` | Pomeranje ili preimenovanje | `mv stari.txt novi.txt` |
| `rm` | Briše fajl | `rm fajl.txt` |
| `cat` | Ispisuje sadržaj fajla | `cat notes.txt` |
| `man` | Otvara pomoć za komandu | `man ls` |
| `sudo` | Izvršava komandu sa administratorskim pravima | `sudo apt update` |

Terminal je važan deo Linux rada jer omogućava brzinu, preciznost i pristup alatima koji često nemaju GUI ekvivalent.[cite:11]

## 6. Instalacija programa

Na Debian/Ubuntu/Mint sistemima osnovni alat za pakete je APT, a tipičan tok rada izgleda ovako:[cite:1][cite:11]

```bash
sudo apt update
sudo apt upgrade
sudo apt install ime-paketa
sudo apt remove ime-paketa
```

Drži se zvaničnih repozitorijuma i proverenih izvora. Instalacija sa nasumičnih sajtova je loša praksa, posebno za početnika.[cite:9]

## 7. Dozvole i vlasništvo

Svaki fajl i direktorijum imaju vlasnika i dozvole pristupa. Ovo je osnova bezbednosti i administracije u Linuxu.[cite:11]

Najčešće komande:

```bash
ls -l
chmod +x skripta.sh
chown korisnik:korisnik fajl.txt
```

Ako ne razumeš dozvole, nemoj naslepo koristiti `chmod 777`; to je često loše i nepotrebno rešenje.[cite:11]

## 8. Održavanje sistema

- Redovno ažuriraj sistem i pakete.[cite:9]
- Čitaj poruke greške umesto da ih preskačeš; Linux obično kaže šta nije u redu.[cite:11]
- Proveravaj logove kada nešto ne radi, umesto nasumičnog reinstaliranja.[cite:11]
- Uči postepeno: fajlovi, procesi, mreža, servisi, pa tek onda napredna administracija.[cite:1][cite:11]

## 9. Komande za svakodnevni rad

```bash
whoami
uname -a
df -h
free -h
ps aux
top
ip a
ping 1.1.1.1
history
clear
```

Ove komande pomažu da brzo proveriš korisnika, kernel, disk, memoriju, procese, mrežu i istoriju rada u terminalu.[cite:11]

## 10. Greške koje početnici najčešće prave

- Brišu fajlove bez provere putanje, posebno sa `rm`.[cite:11]
- Koriste `sudo` za sve, i kada nije potrebno.[cite:11]
- Menjaju particije bez backup-a.[cite:9]
- Očekuju da Linux radi identično kao Windows, pa ignorišu razlike u filozofiji i alatima.[cite:3][cite:8]

## 11. Redosled učenja

1. Kretanje kroz fajlove i direktorijume.[cite:11]
2. Uređivanje fajlova i rad sa tekstom u terminalu.[cite:11]
3. Instalacija i uklanjanje paketa.[cite:1][cite:11]
4. Dozvole, vlasništvo i `sudo`.[cite:11]
5. Procesi, servisi i logovi.[cite:1][cite:11]
6. Mreža, SSH i osnovna bezbednost.[cite:1][cite:11]

## 12. Kratka praksa za prvi dan

```bash
pwd
ls -la
mkdir linux-proba
cd linux-proba
touch test.txt
echo "zdravo" > test.txt
cat test.txt
cp test.txt kopija.txt
mv kopija.txt novo-ime.txt
ls -la
```

Ova mala vežba pokriva navigaciju, pravljenje fajlova, upis teksta, čitanje, kopiranje i preimenovanje, što je dovoljno za prvi stvarni kontakt sa terminalom.[cite:11]
