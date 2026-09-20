# Erlang Bitcoin Miner

Run from PowerShell with Erlang/OTP installed:

```powershell
escript .\project1.escript 4
```

The number is the required count of leading hexadecimal zeroes in each SHA-256 hash. The server prints each coin as `input<TAB>hash` and also mines with one actor per online scheduler. Find the server's reachable address with `ipconfig`; on another machine, run `escript .\project1.escript <server-ip>`. The worker prints nothing and sends coins to the server. Set `$env:MY_IP = '<local-ip>'` before starting a node if the selected network interface is wrong.

## Work unit and timing

The work unit is **500,000 candidate nonces** per request to the boss actor. On September 19, 2026, I compared work units by mining 500 coins at k=4 per trial. The boss ran with four Erlang schedulers (`$env:ERL_FLAGS = '+S 4'`); the second machine's worker had 16. A temporary measurement copy of the same mining loop changed the unit size and stopped each timed phase after 500 coins. The final program still takes one argument.

| Strings per unit | Boss only: real time | Boss + worker: real time |
| ---: | ---: | ---: |
| 1,000 | 8.205 s | 8.619 s |
| 10,000 | 8.383 s | 4.240 s |
| 50,000 | 8.024 s | 2.540 s |
| **500,000** | **8.409 s** | **2.313 s** |
| 1,000,000 | 9.424 s | 2.278 s |
| 2,000,000 | n/a | 2.466 s |
| 5,000,000 | n/a | 2.328 s |

Times are averages where a size was repeated: two boss-only runs at 500,000 and 1,000,000, four two-machine runs at 500,000, two at 1,000,000 or larger, and three at 50,000. The smaller sizes each have one run. **500,000** was chosen because 1,000,000 was only about 1.5% faster with two machines in these samples, while it was about 12% slower with the boss alone.

At 500,000, the two machines used an average of **45.4 s combined CPU time** per 500-coin run over **2.313 s real time**, a CPU/real ratio of **19.6** across 20 schedulers. The boss-only ratio was about **4.0**. Adding the worker reduced real time by about **3.6x** for the same 500-coin task. Each timed phase started after a one-second warmup; coin output was captured and its SHA-256 hashes verified.

## Example result for input 4

From a run of `escript .\project1.escript 4`:

```text
hkarimkonda;3MJ	0000bd8aa4077b8e3b43e3e378b6eb567fa6b93ce5231a33a74ddf6ff79e62a3
hkarimkonda;UX7	00009e6aaf28728ed691ff4e6ca980ddada643efa070795c36c903fd56b51e22
hkarimkonda;480L	00005e534e1672d65e2a8da9bb26ae1e9f5488b0198794831de878e10bd4ac55
```

Coin order can vary because workers run concurrently. The prefix `hkarimkonda;` is the author's GatorLink ID.

## Most difficult coin found

`hkarimkonda;20GCR` hashes to `00000002d834eb14df32c4f2ddeb1ae8db4f34a4373af56e466e9a6c2704f125`, with **7 leading hexadecimal zeroes**. The hash was verified independently with Python's SHA-256 implementation.

## Distributed run

The largest configuration tested was **2 working machines**: a boss on `192.168.0.152` and a worker on `192.168.0.26`. The boss gives disjoint nonce ranges to local and remote worker actors, and only the boss prints coins.
