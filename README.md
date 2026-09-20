# Erlang Bitcoin Miner

Run from PowerShell with Erlang/OTP installed:

```powershell
escript .\project1.escript 4
```

The number is the required count of leading hexadecimal zeroes in each SHA-256 hash. The server prints each coin as `input<TAB>hash` and also mines with one actor per online scheduler. Find the server's reachable address with `ipconfig`; on another machine, run `escript .\project1.escript <server-ip>`. The worker prints nothing and sends coins to the server. Set `$env:MY_IP = '<local-ip>'` before starting a node if the selected network interface is wrong.

## Work unit and timing

The work unit is **1,000 candidate nonces** per request to the boss actor. I compared sizes by mining 500 coins at k=4 on Windows with four Erlang schedulers (`$env:ERL_FLAGS = '+S 4'`). A temporary measurement version stopped after 500 coins and allowed work unit changes; those controls were removed from the final program. The 1,000 nonce unit had the shortest real time in this run:

| Nonces per unit | CPU time | Real time | CPU / real |
| ---: | ---: | ---: | ---: |
| 1,000 | 30,937 ms | 7,956 ms | 3.89 |
| 5,000 | 32,562 ms | 8,160 ms | 3.99 |
| 10,000 | 35,938 ms | 8,994 ms | 4.00 |
| 50,000 | 37,406 ms | 9,375 ms | 3.99 |

The CPU to real time ratio of 3.89 in the k=4 timed run shows that nearly four cores were used. These are measurements from one run per size, so the ordering can vary with machine load.

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

The previous project record reports **2 working machines**: a server and a remote worker. This cleanup was checked with a server and worker process on one machine. The server gives disjoint nonce ranges to local and remote worker actors, and only the server prints coins.
