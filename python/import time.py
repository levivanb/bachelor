import time
import random
import pandas as pd
from pytrends.request import TrendReq

# -----------------------------
# Config
# -----------------------------
GEO = "US"
TIMEFRAME = "2024-06-01 2024-12-31"
CATEGORY = 0
SLEEP_BASE = 2.5
SLEEP_JITTER = 2.5
MAX_RETRIES = 5

QUERIES_CSV = "queries_sentiment.csv"
OUT_CSV = "trends_weekly.csv"


def sleep():
    time.sleep(SLEEP_BASE + random.random() * SLEEP_JITTER)


def fetch_one(pytrends: TrendReq, kw: str) -> pd.DataFrame | None:
    """
    Returns weekly interest_over_time dataframe with columns: date, svi
    or None if no data.
    """
    pytrends.build_payload(
        kw_list=[kw], cat=CATEGORY, timeframe=TIMEFRAME, geo=GEO, gprop=""
    )
    df = pytrends.interest_over_time()

    if df is None or df.empty:
        return None

    if "isPartial" in df.columns:
        df = df.drop(columns=["isPartial"])

    cols = [c for c in df.columns if c != "isPartial"]
    if kw in cols:
        df = df.rename(columns={kw: "svi"})
    elif len(cols) >= 1:
        df = df.rename(columns={cols[0]: "svi"})
    else:
        return None

    df = df.reset_index().rename(columns={"date": "date"})
    return df[["date", "svi"]]


def read_queries(path: str) -> pd.DataFrame:
    """
    Robustly read queries file. Your file is semicolon-delimited.
    """
    df = pd.read_csv(path, sep=";", dtype=str)
    df.columns = df.columns.str.strip()

    if not {"tic", "query"}.issubset(df.columns):
        df = pd.read_csv(path, sep=None, engine="python", dtype=str)
        df.columns = df.columns.str.strip()

    for c in df.columns:
        df[c] = df[c].astype(str).str.strip()

    return df


def main():
    queries = read_queries(QUERIES_CSV)
    print(f"Loaded {len(queries)} queries")

    if not {"tic", "query"}.issubset(set(queries.columns)):
        raise ValueError(f"Missing required columns")

    queries = queries.dropna(subset=["tic", "query"])
    queries = queries[(queries["tic"] != "") & (queries["query"] != "")]
    queries = queries.drop_duplicates(subset=["tic"], keep="first").reset_index(
        drop=True
    )

    # Initialize TrendReq with ONLY basic parameters per documentation
    # DO NOT use retries/backoff_factor - they cause method_whitelist errors
    pytrends = TrendReq(hl="en-US", tz=360, timeout=(10, 25))

    rows = []
    failures = []

    for idx, r in queries.iterrows():
        tic = r["tic"].strip()
        kw = r["query"].strip()

        print(f"[{idx + 1}/{len(queries)}] {tic}: ", end="", flush=True)

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                df = fetch_one(pytrends, kw)
                if df is None or df.empty:
                    print("no data")
                    failures.append(
                        {"tic": tic, "query": kw, "reason": "no_data_from_google"}
                    )
                else:
                    df["tic"] = tic
                    df["query"] = kw
                    rows.append(df)
                    print(f"✓ {len(df)} points")
                break
            except Exception as e:
                error_msg = str(e)
                if "429" in error_msg:
                    print(f"rate limit (waiting 60s)...", end="", flush=True)
                    time.sleep(60)

                if attempt == MAX_RETRIES:
                    print(f"✗ {error_msg[:50]}")
                    failures.append(
                        {"tic": tic, "query": kw, "reason": error_msg[:100]}
                    )
                else:
                    sleep()

        sleep()

    out = (
        pd.concat(rows, ignore_index=True)
        if rows
        else pd.DataFrame(columns=["date", "svi", "tic", "query"])
    )

    if not out.empty:
        out["date"] = pd.to_datetime(out["date"]).dt.date
        out = out[["date", "tic", "query", "svi"]]

    out.to_csv(OUT_CSV, index=False)

    if failures:
        pd.DataFrame(failures).to_csv("trends_failures.csv", index=False)

    print(f"\n{'=' * 60}")
    print(f"✓ {len(rows)}/{len(queries)} successful → {OUT_CSV}")
    if failures:
        print(f"✗ {len(failures)} failed → trends_failures.csv")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
