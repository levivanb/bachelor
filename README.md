# Revisiting FEARS — Replication Repository

This repository contains all code used in *Revisiting FEARS* by Levi van Boekel.

---

## Repository structure

### `python/`
Web scraper for collecting Google Search Volume Index (SVI) data from Google Trends. Run this first to produce the raw trends CSV files that feed into the Stata pipeline.

### `stata/`
The main replication code. Contains six consolidated do-files that reproduce all results in the paper. See the replication handbook (`replication_handbook.pdf`) for a full description of each file and the required raw data.

### `stata_old/`
The original, unedited do-files written during the research process (~94 files). Included for transparency but **not intended for replication** — the code in `stata/` should be used instead.

---

## Quick start

1. Clone the repository.
2. Run the Python scraper in `python/` to download Google Trends data, or simply use the raw CSV files directly in `stata/data_raw/`.
3. Obtain CRSP data from WRDS and place it in `stata/data_raw/` (see replication handbook).
4. Open `stata/code/00_master.do`, set the path at the top to match your machine, and run.
