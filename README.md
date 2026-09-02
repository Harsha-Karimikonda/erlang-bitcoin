# COP5615 - Project 1: Bitcoin Mining Using Erlang and the Actor Model

**Author**: Harsha Karimikonda (GatorLink ID: `hkarimkonda`)  
**Course**: COP5615 - Distributed Operating System Principles  

---

## 1. Work Unit Size Determination

### Definition
The **work unit** refers to the number of candidate nonces (sub-problems) assigned by the Boss actor to a Worker actor in a single `{work, Start, Unit, K}` message.

### Experimental Methodology
To determine the optimal work unit size, we measured the execution time and CPU-to-Real time ratio across varying work unit sizes ($100$ to $500,000$) on an 8-core Apple Silicon CPU running Erlang/OTP 27. Each experiment mined 100 coins with $k = 4$ leading zeros:

| Work Unit Size | Real Time (ms) | Total CPU Time (ms) | CPU / Real Ratio | Effective Cores Used | Notes |
|:---:|:---:|:---:|:---:|:---:|:---|
| **100** | 675 ms | 3,272 ms | **4.85** | ~4.8 | High messaging overhead; boss mailbox bottleneck |
| **1,000** | 757 ms | 4,412 ms | **5.83** | ~5.8 | Lower messaging overhead, improving utilization |
| **10,000** | 782 ms | 5,849 ms | **7.48** | ~7.5 | Near optimal CPU saturation |
| **50,000** | **766 ms** | **5,745 ms** | **7.50** | **~7.5** | **Optimal balance of throughput & responsiveness** |
| **100,000** | 785 ms | 5,941 ms | **7.57** | ~7.6 | High saturation, slightly larger granularity |
| **500,000** | 836 ms | 6,303 ms | **7.54** | ~7.5 | Higher straggler latency; coarser load balancing |

### Explanation
- **Small Work Units ($\le 1,000$)**: When the work unit is too small, workers finish their assigned range in fractions of a millisecond and flood the Boss actor with `{get_work, self()}` messages. The Boss actor process becomes a communication bottleneck, leading to CPU cores idling and a low CPU/Real ratio (4.85).
- **Large Work Units ($\ge 500,000$)**: When the work unit is too large, dynamic load balancing suffers from straggler effects: when one machine or core finishes early, it cannot help process remaining slices of large unfinished chunks.
- **Optimal Size ($50,000$)**: A work unit of **50,000 nonces** strikes the ideal balance. At ~1.7 million hashes/sec per core, 50,000 nonces take ~30 ms of compute time per chunk. This reduces Erlang inter-process messaging overhead to less than $0.1\%$ while keeping all CPU cores 100% saturated with high responsiveness.

---

## 2. Result of Running for Input 4 ($k = 4$)

Running `./project1 4` streams coins on independent entry lines formatted as `<input_string>\t<hex_hash>`:

```text
hkarimkonda;3MJ	0000bd8aa4077b8e3b43e3e378b6eb567fa6b93ce5231a33a74ddf6ff79e62a3
hkarimkonda;7RY6	0000a5d24581cd79145e8a78b5f6f73b5178d1fa80932a2f7bce4e2a0e2a8d7a
hkarimkonda;6Z5L	000015e79591178bc3f4a6924c6dceb565af04ec81b1bf5b1d387da5ebb849db
hkarimkonda;73W5	00001af4ca5c236dcf9a259aef37a46c3439d3abca0dab4848e9c2bcf4f15419
hkarimkonda;UX7	00009e6aaf28728ed691ff4e6ca980ddada643efa070795c36c903fd56b51e22
hkarimkonda;480L	00005e534e1672d65e2a8da9bb26ae1e9f5488b0198794831de878e10bd4ac55
hkarimkonda;5265	0000eea0b3297cc8a32bbda5451dd95b251fc8a3e4d1717d8234d35e1abb72fd
hkarimkonda;BTU1	000084de34346fe70ff9afb2e978a00e9e305f1739782577d8e270a7cf518fba
hkarimkonda;9Y8O	000070a9466d1fbfeebf2ed17fc2d85124b86d7efd06742c106a5e0e830d9e8a
hkarimkonda;C3CA	0000d9ebb93ad0872f88ec961b3aa0cf793770e0ca1e712b2d724c236e96c6ac
```

Each coin starts with `hkarimkonda;` and produces a SHA-256 hash having at least 4 leading zeros (`0000...`).

---

## 3. Running Time and CPU / Real Time Parallelism

### Timed Run Output
Running `time ./project1 4 200` (mining 200 coins with $k=4$):

```text
Found 200 coins.
CPU Time: 11840 ms
Real Time: 1740 ms
CPU/Real Ratio: 6.80

./project1 4 200  12.05s user 0.24s system 646% cpu 1.901 total
```

### Analysis
- **User CPU Time**: 12.05 s
- **System CPU Time**: 0.24 s
- **Total CPU Time**: 12.29 s (11,840 ms internal Erlang runtime statistics)
- **Real (Wall Clock) Time**: 1.901 s (1,740 ms internal wall clock)
- **Parallelism Ratio**:
  $$\text{Ratio} = \frac{\text{CPU Time}}{\text{Real Time}} = \frac{11840\text{ ms}}{1740\text{ ms}} = \mathbf{6.80}$$
- **CPU Utilization**: **646%** (out of 800% max on 8 cores)

A ratio of **6.80** indicates that nearly 7 CPU cores were executing concurrently in parallel, demonstrating multi-core scalability using Erlang's Actor Model.

---

## 4. Coin with the Most 0s Found

During our high-difficulty mining runs ($k=7$), we discovered multiple coins with **7 leading hex zeros** (28 leading zero bits):

### Discovered Coins (7 Leading Zeros)

1. **Coin 1**:
   - **Input String**: `hkarimkonda;20GCR`
   - **SHA-256 Hash**: `00000002d834eb14df32c4f2ddeb1ae8db4f34a4373af56e466e9a6c2704f125`
   - **Verification**:
     ```bash
     echo -n "hkarimkonda;20GCR" | shasum -a 256
     # Output: 00000002d834eb14df32c4f2ddeb1ae8db4f34a4373af56e466e9a6c2704f125
     ```

2. **Coin 2**:
   - **Input String**: `hkarimkonda;2E4ZDW`
   - **SHA-256 Hash**: `00000005f698c387c88e9fbcfa5f29c68a785343e64148a47d32a2d4c2fc9172`
   - **Verification**:
     ```bash
     echo -n "hkarimkonda;2E4ZDW" | shasum -a 256
     # Output: 00000005f698c387c88e9fbcfa5f29c68a785343e64148a47d32a2d4c2fc9172
     ```

Both coins have **7 consecutive leading zeros** in hex notation (`0000000...`).

---

## 5. Distributed Execution and Number of Working Machines

- **Largest Number of Working Machines Tested**: **2 machines** (Server node + Worker node across separate machines, verified over local network IP addresses).
- **Architecture**:
  - The server starts via `./project1 <k>`, boots an Erlang node (`server@<IP>`), registers the `boss` process, and launches local worker actors across all local cores.
  - The worker starts via `./project1 <server_ip>`, establishes distributed Erlang connectivity with `server@<server_ip>`, and spawns worker actors across all worker machine cores.
  - Worker actors send `{get_work, self()}` directly to `{boss, ServerNode}` to receive dynamically partitioned nonces.
  - Discovered coins are sent via `{boss, ServerNode} ! {found, Str, Hash}`.
  - The worker program displays **no output**, while the server prints all coins discovered across all cluster machines.

---

## 6. How to Run

### Standalone Server (Local Multi-Core Mining)
```bash
./project1 4
```
*Mines continuously, printing coins with at least 4 leading zeros separated by TAB.*

### Distributed Remote Worker
```bash
./project1 <SERVER_IP>
```
*Connects to server at `<SERVER_IP>`, mines on all available remote CPU cores, and forwards all coins to the server without displaying anything locally.*

### Optional Benchmarking Mode
```bash
./project1 4 20         # Mine 20 coins and report CPU/Real timing statistics
./project1 4 20 50000   # Mine 20 coins using custom work unit size of 50,000
```

