# Myanmar Open Wordnet (MOW)

The Myanmar Open Wordnet (MOW) is a freely-available semantic dictionary of the
Myanmar/Burmese language, part of the
[Open Multilingual Wordnet](https://omwn.org).
It is built using the *expand* approach from Princeton WordNet synsets.

Browse the wordnet at **https://omwn.github.io/mow/**.

## Data

- Language: Myanmar/Burmese (`my`)
- Version: 0.1.3
- Source tab file: `mow-0.1.3-mya_20171005165336.tab`
- Licence: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

## Citation

Wenjie Wang. n.d. Myanmar Open Wordnet (MOW). <https://wordnet.burmese.sg/>

## Using with the `wn` module

```python
import wn
wn.download("https://github.com/omwn/mow/releases/latest/download/wnmow.tar.xz")
words = wn.words("ကုမ္ပဏီ", lang="my")
```

## Build

Prerequisites: `uv`, `wget`, `xmlstarlet`, Python 3.11+.
Requires a local clone of [cygnet](https://github.com/omwn/cygnet) at `../cygnet`.

```bash
bash build.sh      # produces docs/ web UI + build/wnmow-*.tar.xz
bash run.sh        # serve docs/ locally for testing
```

## Release

1. Run `bash build.sh` to produce fresh DB files and the LMF tarball.
2. Create a GitHub release and upload:
   - `build/wnmow-VERSION.tar.xz`
   - `docs/mya-cygnet.db.gz`
   - `docs/mya-provenance.db.gz`
3. In **Settings → Pages**, set source to **GitHub Actions**.
4. The Pages workflow fires automatically on release and deploys the web UI.
