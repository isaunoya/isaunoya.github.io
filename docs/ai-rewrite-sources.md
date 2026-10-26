# AI rewrite source map (local authoring notes)

The lecture and editorial PDFs contain the final explanations. This file records source
provenance and verification notes; `docs/` is not copied into the generated site.
All problem paths below are relative to the author's `noya-problems` repository.
The four contest decks cover only the author’s contributed problems that were
officially used. They are selected-problem editorials, not full-contest solutions.

| Contest | Problem | Author source | Final explanation |
| --- | --- | --- | --- |
| 2025 Online II | C Jiaxun! | `2025ICPC-online/jiaxun/std.cpp` | Hall's seven subset constraints |
| 2025 Online II | D Arcane Behemoths | `2025ICPC-online/behemoth/std.cpp` | Sorted contribution coefficients |
| 2025 Online II | J Reconstruct the tree | `2025ICPC-online/construct-tree/std.cpp` | Neighbor fingerprints, complete multipartite endpoint graph, center construction |
| 2025 Online II | L Xor Mirror | `2025ICPC-online/xor-mirror/st.cpp` | Official ordinary-sum query; concise block/XOR mapping, then a persistent index Trie with subtree sharing and periodic rebuilding |
| 2025 Guangxi | E Elimination (easy) | `2025GXCPC/str-easy/std.cpp`, `2025GXCPC/sol.md` | Quadratic LCP DP |
| 2025 Guangxi | F Elimination (hard) | `2025GXCPC/str-hard/std.cpp`, `2025GXCPC/sol.md` | Binary search over a prefix-closed substring set, with two independent polynomial fingerprints (the author’s later solution) |
| 2025 Guangxi | L Lost in MST | `2025GXCPC/MST/std2.cpp`, `2025GXCPC/sol.md` | Divisor candidate graph, threshold connectivity, restore duplicate values |
| 2025 Sichuan | A Minimum Product | `2025SCCPC/sol.md`, `2025SCCPC/shortest_path/std.cpp` | Layered DP by the sum of the first weight (the author's written solution) |
| 2025 Sichuan | C Optimal Time | `2025SCCPC/sol.md`, `2025SCCPC/change-or-not/std.cpp` | Complete synchronous Bellman iteration; residual error certificate and a proved 300-update bound using an exact finite-range upper certificate |
| 2025 Sichuan | I Distinct Suffixes | `2025SCCPC/suffix/std.cpp` | Reversed Trie node count |
| 2025 Sichuan | L abc | `2025SCCPC/sol.md`, `2025SCCPC/intervals/std.cpp` | Pairwise count differences, then corrections for missing characters and monochrome runs |
| 2024 CCPC Female | D Excellent Splitting | `2024女生赛/lis+lds/solution.md`, `std.cpp` | LIS/LDS length and disjoint pair polynomial; independent weighted scans give a proved error bound |
| 2024 CCPC Female | E Centroid Tree | `2024女生赛/centers/solution.md`, `std.cpp` | Descending labels, DSU child components and root metadata |
| 2024 CCPC Female | I String Duplication | `2024女生赛/string-copies/solution.md`, `std.cpp` | SAM on S, SS, SSS; proof of stable increments after two copies |
| 2024 CCPC Female | J GCD squares | `2024女生赛/gcd^2/solution.md`, `std.cpp` | Jordan J2, small divisors and offline weighted point queries |

Official listings: QOJ contests 2524, 2152, 1841 and Nowcoder contest 110811.
Codeforces mirrors: gyms 106072, 105949, 105487. The unused Online II `collision`
material is excluded. The earlier weighted Xor Mirror query is not the official
query and is excluded.

The Sichuan C source omits the wait action from subsequent iterations. At N=48,
its result 3.65560603 exceeds the valid wait policy cost 3.47297605. The rewritten
Bellman update includes both actions. The presentation now proves a 300-update bound in exact arithmetic for every
N <= 100000 using geometric contraction and an exact finite-range integer
certificate. The residual remains the stopping rule in floating-point code;
see `sichuan-c-iteration-bound.md` for the derivation and reproducible verifier.

## Lectures

Originals: `ppt/isaunoya/根号数据结构&根号分治/slide.typ` and
`ppt/isaunoya/随机化选讲/slide.tex`, together with their PDFs.
The canonical rewritten sources are `lectures/{sqrt-decomposition,randomization}/slides.typ`.
`npm run build` runs `scripts/build-presentations.mjs` before the site build, compiling
these sources into `public/lectures/{slug}.pdf`; the site copies them to
`dist/lectures/`. Generated PDFs are ignored by Git. CI installs Typst and
Noto CJK fonts before invoking the same command. No author-local paths are needed.
About links directly to these two PDFs, one entry per lecture. The four contest
editorials have canonical Touying sources in `editorials/{slug}/slides.typ`; all six PDFs have no intermediary HTML pages,
search entries, duplicate prose sources, or downloadable source ZIPs.

Presentation outlines use Touying's linked progressive outline, with short
section names and the current section highlighted. The complete deterministic
CF1891E solution and the detailed multiplicative-function proof are in the
randomization appendix, linked from the relevant main-text discussion.

P8330 was checked against brute force for every ternary array of lengths 2–7
with at least two distinct values: 3258 cases, comparing every target value's
optimum. The streaming light-color algorithm uses O(n) space. CF1891E's greedy
was exhaustively compared with all deletion subsets on short arrays. The
completely multiplicative construction's finite-range inequalities are checked
for every n from 200 to 1000000 by `lectures/randomization/verify-prime-cover.py`.

Randomized and heuristic examples retain their actual assumptions: a verified
candidate is not a proof that repeated failure means impossibility. Fixed-modulus
counts and reused fingerprints are not described as independent random trials.

The final statement pass also checked CF763E (n,q <= 100000, K <= 5), P8819
(single-edge state guarantees), P3765 (winner-dependent updates and final -1),
CF739E (n <= 2000 and 1e-4 output tolerance), CF1198F (positive values up to
1e9), and Gym103469E (connected simple graph, non-adaptive interactor, 60 queries)
against their linked original statements. Online II D and J bounds were checked
against the official statement PDF at
https://codeforces.com/gym/106072/attachments/download/33156/statement.pdf .

## Problem-link and approximation audit (2026-10-24)

`ai-rewrite-link-audit.json` maps all 33 + 4 square-root topics, 25 + 4 randomization
topics, and 15 officially used problems to their actual statement URLs.
The six model/algorithm examples have no uniquely identified public problem
statement; no invented link is assigned. P7811 was identified as the original
interval-modulo minimum problem. The original Fourier example is 锅, available
at https://zijian-lv.com/problem/45 and https://qoj.ac/problem/300 .

HDU7337, 百度之星2023决赛H（小度的双色球）, Multiply Then Plus, and
CCPC Final2022 L now link directly to their statements. The original P5021
related-problem reference is retained. Gym104207H redirects to the attachment
list, so its statement link now opens page 11 of the official PDF instead.
The original color problem asks for an expectation: intersection size c gives
n/c modulo 998244353, with -1 when c is zero; this final step is included.

Every absolute link in the two slide sources occurs as an actual
PDF URI annotation. At that audit date, the 15 problem links occurred in both the editorial HTML
and PDF outputs; the current editorial outputs are PDF only. The site PDF assets are compiled from the canonical lecture sources.
External checks used direct HTTP, rendered browser content for 码蹄集, and
web retrieval for sites whose HTTP endpoint rejects automated curl requests.
QOJ contest-list links require login and are labeled accordingly; the
individual official editorial problem links use the accessible contest mirror.

Recommended block sizes use approx (≈). The q and n same-order assumption
uses q=Theta(n), preserving the asymptotic meaning.

## Additional examples (2026-10-24)

The original 33 + 25 topics are retained. Eight examples were added to fill
prerequisite gaps; each has its statement link, constraints, algorithm, proof,
complexity and boundary conditions in the slides:

- CF342E: time batches, multi-source BFS and recent red vertices; binary-lifting LCA costs O(log n) per distance.
- ABC219G: degree classification and timestamped broadcasts; values are snapshots at broadcast time.
- P4168: online range mode; full-block modes, boundary candidates, block-boundary frequency prefixes and touched-counter clearing give O(B) queries with O(n+KC+K²) space. Original-value decryption and smallest-value ties are retained; occurrence lists are an optional memory-saving tradeoff.
- ABC367F: two independent finite-field multiset fingerprints; nonzero count differences use p > n.
- CF364D: sample a divisible witness, count gcds, then sum over prime-exponent coordinates; no scan of all n elements for every divisor.
- CF1523D: sample at most 15 set bits, project all rows, use superset SOS counts; threshold is ceil(n/2).
- P1923: three-way randomized Quickselect, zero-based rank, duplicates, expected O(n) and worst-case O(n²).

Run `python3 lectures/verify-examples.py` for deterministic small-case differential
checks. This checks implementation identities and examples; the probability and
complexity proofs are supplied separately in the slides. The prime-cover script
verifies the finite inequalities for every n from 200 to 1,000,000.

The original problems remain the author’s problem-setting work. `[AI rewrite]`
appears only in the six website PDF entry titles; no AI-editing note is repeated
in the PDFs. Their cover author is `isaunoya`.

## Touying version

The two decks use Touying 0.8.0, checked against Typst Universe and the official
GitHub latest release on 2026-10-24. It requires Typst 0.15; local Typst 0.15.1
and the CI setup satisfy this. The original square-root deck used Stargazer. Both revised decks now use
Stargazer, retaining the chapter navigation, title bar, author, institution,
slide count and progress bar. Revision dates are omitted. Article mode is not enabled.

Gym105487J, 最大公因数的平方和, is also included in the square-root deck
as a six-slide synthesis: Jordan J₂, small/large divisor classification, offline
weighted points and a second block decomposition for many updates. It follows
the original `2024女生赛/gcd^2/std.cpp` divisor-table implementation, with
O(n log n + q) space. The exposition uses disjoint divisor classes and overlapping weighted points,
without a separate page of numerical substitutions.

## Foundations and presentation revision (2026-10-25)

The square-root deck introduces the current-interval invariant, four endpoint
operations and the Mo ordering/movement analysis before P4137. P4887 adds
second offline processing: range events preserve O(q) storage, while a prefix
scan evaluates the expensive pair-count increments. Its statement was checked
against https://www.luogu.com.cn/problem/P4887 : n,q <= 100000 and
0 <= a_i,k < 2^14. The k > 14 and k = 0 cases are handled separately.

The randomization foundations distinguish exact answers with random running
time from bounded work with possible error, and state the fixed-input,
independence and whole-run error-budget assumptions before applications.
Fingerprints, witness sampling and randomized order are presented separately.
Repetitive numerical substitutions and duplicated demonstrations are removed;
examples are retained where they establish an invariant or counterexample.

The cover has no editorial slogan. The AI rewrite label appears only at the
website PDF entries. Covers and footers omit revision dates. Each named
problem retains a clickable statement link.

`python3 lectures/verify-mos.py` exhaustively checks short arrays and all
intervals, then random query sets, including k = 0 and k above the bit width.
It also checks the CF1891E bandwidth counterexample against every size-k
subset for k = 1, 2, 3. The completed run passed 1,264,704 query comparisons.

`python3 lectures/verify-random-foundations.py` checks canonical prefix
stack identifiers against explicit cancellation (730,605 substring checks)
and the GCD search distribution against exhaustive partitions (9,324 arrays).
The tests support the implementation; the lower-bound argument is stated
separately and is not claimed to justify a small fixed number of retries.

Problem statements precede the first hint or solution. Touying pause overlays
reveal the reasoning on the next PDF step; initial problem titles do not
reveal the method. Logical slide counts and physical PDF pages therefore differ.

## Reader review and statement checks

The repeated top-right HDU mark is omitted; the cover retains the institution.
The introductory cost balance now follows sequence blocking. The existing cut
diagram and random-prefix diagram precede their probability calculations.

P8330's nonconstant-input and shift-range assumptions and P7811's full-data
constraints were checked against their Luogu statements. P7811 processes
large-modulus events through threshold buckets, keeping one reusable node per
original query instead of storing all expanded subqueries. Independent checks
matched 24,000 queries and 73,126 scheduled events against direct answers.

The Matiji statement for 2023 Baidu Star Final H was checked through the
public statement route linked in the deck. Boxes are sampled uniformly with
replacement until one contains both distinct requested colors; colors within
each box are distinct. The original expectation, modulus, failure output and
size constraints precede the pause; the intersection reduction follows it.

The CF436E statement asks for at least the required number of stars and an
explicit plan. Its strictly increasing costs justify reducing to exactly that
number. The deck states the storage cost of retaining predecessor states and
does not claim that the conservative bandwidth guarantee meets the original
runtime limit. CF1799F likewise separates the proved bandwidth budget from
the problem's implementation budget.

P3792's extreme-value check reduces the normalized difference polynomial's
degree to the query length minus one. CF1418G uses two independent fingerprints
and a union bound over all prefix pairs; its sliding-window count was checked
on 9,840 arrays and 317,388 intervals. Balanced Array now states a modulus
condition preserving nonzero integer coefficients. The dynamic-reachability
section states the multivariate evaluation lemma before applying it.

The randomized Graph Cuts discussion proves recovery only for a fixed graph
and cut. Deleting its returned edge makes later graph states adaptive, so the
deck points to the square-root lecture's deterministic solution for a complete
original-problem guarantee.

## Content completion and editorial presentations (2026-10-26)

All 15 officially used problems now have stepped Touying solutions, in four
editorial decks. Each problem opens with its statement and clickable official
link, then reveals a solution after a pause. The former eight `content/about/`
article/index files were replaced by these canonical sources. About keeps the original contest links and adds separate solution links
to `/solutions/{slug}.pdf`; no separate editorial HTML routes
are generated. `npm run build` compiles all six PDFs from their Typst sources.

Guangxi F follows the author’s later binary-search/hash-set solution, as
explicitly requested. Prefix closure proves that inserting one substring per
position is sufficient. The earliest incorrect membership query is on a fixed
ideal execution, allowing a union bound without assuming adaptive queries are
independent. E also supplies a rolling LCP implementation using linear memory.

Sichuan C now proves a bound on the iteration count, rather than leaving K
unspecified: optimal-value potential contraction gives a geometric tail; an
integer upward-rounded robust operator covers every N <= 100000. After 40
rounds its maximum is 9788341 / 1000000 < 10. The resulting residual width at
h_299 is at most 1000 * (9/10)^259 < 1e-8, so at most 300 Bellman updates suffice
in exact arithmetic. This is a proof with exhaustive finite integer verification,
not a claim that 100 iterations always suffice, nor a formal floating-point
rounding certificate. A separate analytic O(sqrt(N) log(N/epsilon)) iteration
bound is supplied. Run `editorials/verify-sichuan-c-bound.cpp` to reproduce the
integer upper bound; the large-integer final inequality is also checked by
`python3 editorials/verify-editorials.py`.

The two topic decks retain their original problems and receive missing execution
orders, complete optional solutions, and probability budgets. Detailed changes
and remaining assumptions are recorded in `content-completeness-review.md`.

## Xor Mirror: persistent index Trie

The L section now presents the block idea in two slides, followed by a persistent
Trie alternative. Engineering details such as descriptor layout and reference
counting are omitted from the slides. The Trie stores immutable nodes and
XOR-tagged subtree references; only partially covered boundary nodes are copied.
Each update creates O(log N) nodes. The 64 MB limit is addressed by periodically
extracting the current array and rebuilding in an O(N)-sized pool. This gives
amortized O(log N) updates, worst-case O(log N) queries, and O(N) space.

A standalone implementation is `editorials/2025-online-2/xor-mirror.cpp`. Its
`SELF_TEST` mode passed 654240 updates and 2160000 brute-force query comparisons,
including 48449 rebuilds. The formal sample matches. A maximum-size local stress
run (N=2^18, Q=200000 updates) completed with 12 rebuilds and about 31 MiB peak
resident memory; local timing is not a judge acceptance guarantee.

## Teaching routes and linked appendices

The square-root main route now ends at physical PDF page 51, followed by six
elective groups with prerequisites and return links. All 125 earlier secondary
topics remain. New diagrams explain the second-offline event pipeline and the
light-source/light-target boundary transformation in P8330.

Randomization now starts with Quickselect and develops probability tools through
matrix verification, fingerprints and witness sampling. Its main route ends at
physical page 35. All 112 earlier secondary topics remain; advanced structures,
random-order limitations and construction proofs are separately navigable.
CF436E, CF739E and CF1799F explicitly do not claim that their conservative bands
meet the original time limits. Freivalds, ABC367F, P3765 and CF1523D pair their
error parameters with the corresponding total work.

Contest main routes retain the decisive observations, proofs and complexity.
Sichuan C now uses seven logical slides before optional certificate details;
women D separates the intersection observation from polynomial zero testing.
Additional diagrams cover women I's saturation, Guangxi L's replacement path
and Online II J's center partitions. Guangxi F keeps binary search with hashing,
and Online II L keeps its concise block and persistent-Trie explanations.

This reorganization preserves all 84 statement/model first screens and the
original external URLs. Existing algorithm code and verification assets are
unchanged. The topic authors cross-reviewed each other's frozen versions, and
the primary reviewer checked the substantive changes and rendered pages.

## Randomized interactive problems and traditional techniques (2026-10-27)

The final deck has 186 logical slides plus 37 reveal pages (223 PDF pages).
The main route still ends at physical page 35. Expanded material is elective:
seven interactive examples, graph cut fingerprints, random preprocessing with
an exact fallback, and random-walk 2-SAT. Statements precede their first reveal;
problem titles, official sources and internal indices remain clickable.

`random-interactive-sources.json` records API tags, ratings and accepted records.
An AC record establishes completion, not a particular algorithm. The first pass
read Luogu statement mirrors after CF HTTP 403 responses. This pass read the
CF1438F/CF1705F official statements and editorials in the browser. Their submission
source was not accessible, so the reconstructed methods are not attributed to
those submissions. CF1364E and CF1559D2 now use code supplied by the author.

- CF843B retains the 1+999+999 query split and miss bound below 2.2e-9.
- CF1114E retains at most 30 maximum comparisons and 30 sampled indices;
  the common-prime error bound is below 3.5e-8.
- CF1364E **replaces** the previous zero-bit-witness presentation. The author's
  code samples an OR with at most six one-bits, reads an entire pivot row, and
  descends through complete proper-submask families. Every pivot is recovered
  exactly, including zero. Two main slides explicitly count R+(n-2)+S+(n-1-d),
  where S is descent queries and d counts newly known values after the first pivot.
  Each k-bit descent adds 2^k-2 queries but saves one final query. Thus S-d is at
  most sum(k=2..6)(2^k-3)=109, giving Q<=R+2n+106. The appendix identifies
  A_k=S-d and explains the terminal cases A_0=0 and A_1=-1.
  Exact pair counts and rational A distributions, followed by outward-rounded
  arithmetic, certify Pr(Q>4269)<4.70258e-7 for all n=3..2048. The deck states
  the slightly looser 4.8e-7. This is an independent-uniform sampling model,
  not a claim about the original modulo-based PRNG. A common query cap converts
  overflow to bounded-budget failure. Cached variants only reduce the count.
- CF2074E retains conditional expected contraction for an adaptive interactor;
  the final shrink after query 75 can be output without another query.
- CF1438F uses 420 uniform distinct-vertex triples, selects the two most frequent
  medians, then locates the root conditional on those candidates being its children.
  Pairwise count differences and a union bound give error below 4.902e-5 for
  h=4..18, checked with exact rational upper bounds. Height 3 enumerates all 35
  triples and uses at most 40 queries deterministically. Candidate scanning is
  not unconditional exact verification. Sources:
  https://codeforces.com/problemset/problem/1438/F and
  https://codeforces.com/blog/entry/84589 .
- CF1705F uses two score baselines and balanced groups. Each step recovers two
  bits with one query or three with two; the final at-most-two bits follow from
  baseline totals. The hard bound, including the final answer, is 669. Independent
  random baseline bits reduce expectation to at most 3n/5+3. The expectation proof
  exposes only local information used by selection; it does not condition on full
  baseline totals and then assume independence. Sources:
  https://codeforces.com/problemset/problem/1705/F and
  https://codeforces.com/blog/entry/104881 .

### Author comments and ordinary problems

The comments page https://codeforces.com/comments/with/Retired_Isaunoya was read.

CF1986F follows the author's endpoint-XOR idea in
https://codeforces.com/blog/entry/130762#comment-1162789 and local source
`cp-codes/codeforces/codeforces_round_954_(div_3)/F.cpp`.
A DSU spanning tree fixes all cuts before assigning independent 64-bit non-tree
edge tags. Endpoint XOR/subtree aggregation cancels internal edges. True bridges
are never missed; a nonempty cut cancels with probability 2^-64. Apply the union
bound to all fixed tree cuts. Official statement:
https://codeforces.com/problemset/problem/1986/F .
The linked submission is 267125590; source was read locally, not through a
submission page. The earlier LCA/difference submission was 267081057.

CF1559D2 discussion:
https://codeforces.com/blog/entry/93788#comment-829072 . The author confirms the
submission passed all official tests and was subsequently hacked. We do not
replace this with a claim of original test failure or identify the historical
hack. The source provided in this task is materially different from pure random
pair search: two million draws are followed by exact bitset completion, but only
when both component counts are at most 10000. Once entered, that completion phase
maintains correct component-complement masks and finds a maximum solution.

A newly constructed valid n=100000 input has component counts 10001 and 2:
forest 0 is a 90000-vertex tree containing x plus 10000 isolates; forest 1 isolates
x and connects the rest. Exactly 10000 unordered edges are legal. Uniform
independent endpoint draws (allowing equal endpoints) hit with probability 2e-6;
missing all two million draws has probability about 1.83156%, skips the bitset
phase and returns zero instead of one. This is a construction-specific failure
probability, not an input-averaged rate or a global upper bound. The source's
modulo bias is separate from the ideal uniform model.

A stronger new family partitions vertices into r, A (54999), B (45000).
Forest 0 connects r to B; forest 1 connects r to A; all other vertices are isolated.
With j B-isolates left there are j+9999 A-isolates and component counts
(10000+j,j+1), so the bitset guard fails until the optimum is already reached.
The uniform model has independent geometric stage waits of parameter
2*j*(j+9999)/100000^2. Exact rational moment bounds give mean at least
4793884.771 and variance at most 410846421207. Cantelli certifies failure after
two million attempts above 94.99% for this input. This is neither the historical
hack nor an input-averaged rate. It demonstrates why the 1.83% example is not a
uniform upper bound. Two appendix slides give the full stage/moment derivation.

Let K0,K1 be remaining component counts, k=min(K0-1,K1-1), W=ceil(100000/64),
and C the number of snapshot candidates tested. Each nonempty outer loop merges
at least once, so C<=n*k. Total work is
O((m0+m1+T+n+C)D(n)+(n+K0+K1+k)W), with conservative D(n)=O(log n) for the
source's path compression without rank. Adding size/rank gives O(alpha(n)).
The two static bitset arrays reserve 250080000 bytes in a usual 64-bit-word
layout; resident memory depends on touched rows.

The exact fallback fixes a common root, connects all vertices legal from it,
then pairs representatives outside its component in opposite forests. It reaches
min(c0-1,c1-1) additions. With union by size it takes O((n+m0+m1)alpha(n)) time
and O(n) space. Any preceding finite sequence of legal random merges preserves
that optimum, so keeping T attempts costs O((T+n+m0+m1)alpha(n)) and remains exact.

Random-walk 2-SAT follows Cambridge lecture notes:
https://www.cl.cam.ac.uk/teaching/1920/Probablty/materials/Lecture7.pdf .
The potential Phi(d)=d(2n-d) has conditional drift at most -1 before a solution.
Expected flips are at most n^2; a run of 2n^2 flips misses a satisfiable instance
with probability at most 1/2. Independent runs amplify this. The deck distinguishes
flips from execution time: scanning m clauses costs O(r*m*n^2) across r runs.
It also states the linear-time SCC alternative and why the same proof does not
extend unchanged to 3-SAT or general annealing.

### Reproducible checks

- `python3 lectures/randomization/verify-interactive.py`: original-schedule X-OR
  reconstruction and cutoffs, scaled LowerBound cases, AP sample sets and bounds.
- `python3 lectures/randomization/verify-xor-tail.py`: exact finite distributions
  and outward-rounded certificate for every allowed n; outputs to a temp directory.
- `python3 lectures/randomization/verify-olha.py`: rational Markov/union bounds
  over the complete allowed height range.
- `python3 lectures/randomization/verify-mocha.py`: compiles the exact fallback
  in a temporary directory, tests 3262 executable cases and 44168 small partition
  pairs against original bitset invariants and the exact optimum.
- `python3 lectures/randomization/verify-mocha-tail.py`: rational one-sided
  moment certificate for the stronger family; JSON on stdout.
- `python3 lectures/randomization/verify-mark.py`: exhaustive small transcripts,
  2000 size-1000 simulations and a construction attaining the 669-query bound.

Empirical checks validate implementation and invariants; probability claims use
the stated proofs and finite arithmetic certificates, not observed success rates.

## Teaching-clarity review (2026-10-27)

Both topic decks were read through again for unexplained constants, complexity
terms, assumptions and proof transitions. Thirteen topic-level issues were
addressed, while retaining statement-first reveals and the existing theme.

- CF1364E now counts all four query phases and explains the net descent cost
  2^k-3. Summing k=2..6 gives 109, then the baseline -3 gives 106. The appendix
  connects the same quantities to its distribution recurrence and derives the
  geometric-tail exponent 4272-2n-a from Q>4269.
- Quickselect explains the geometric waiting sum before accumulating scan costs.
- Linear fingerprints introduce invertibility before division in a prime field.
- Kazaee includes the random-bit table for all D distinct initial/update values:
  parallel space is O(t(n+D)); sequential replay remains O(n+q).
- Graph Cuts specifies 1+ceil(log2(m)) layers, derives fixed-cut isolation
  probability at least 1/(2e), and accounts for each group/layer in operation cost.
  The existing adaptive-process limitation remains explicit.
- CF436E derives its exponent constant by dividing star counts and deviations
  by two. A separate slide then accounts for state and reconstruction costs.
- Equidistance derives the common centroid radius from the sum of squared
  pairwise distances before choosing the orthogonal height.
- The multivariate polynomial evaluation bound is proved by induction on the
  last variable and its highest nonzero coefficient polynomial.
- CF1198F explains the nine-prime limit using the minimum ten-prime product.
- Multiply Then Plus defines V as the number of distinct query coordinates,
  includes sorting and ceil(q/T) rebuilding batches, and separates full blocks,
  boundaries and currently changed lines.
- COUNTARI maintains left/right frequencies incrementally across blocks,
  costing O(n) total outside convolution.
- Quantum Communication's 16n/2^16 expectation is qualified by a fixed query
  independent of the random dictionary; correctness stays deterministic.
- Hangzhou I substitutes its tail width into all three query costs, derives
  the cube-root balance, and explicitly reserves one initial query. With
  s=B=3000 there are 3999 giant queries, covering width 11997000 and giving
  the stated bound below 1.54e-8 under the already stated sampling model.

The sqrt deck now has 145 logical slides and 39 reveal pages (184 PDF pages).
Its cross-deck link now uses /lectures/randomization.pdf. The randomization
main route still ends on physical page 35. All modified layouts were checked
with both local PingFang and CI Noto font configurations.
