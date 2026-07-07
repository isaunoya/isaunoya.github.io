#let profile-links = (
  (label: "GitHub", url: "https://github.com/isaunoya"),
  (label: "Codeforces", url: "https://codeforces.com/profile/Retired_Isaunoya"),
  (label: "CP Library", url: "https://isaunoya.github.io/libra/"),
)

#let contest-setting = (
  (
    left: [2024 China Collegiate Programming Contest (CCPC) Female Onsite],
    link: "https://qoj.ac/contest/1841",
    fold: false,
  ),
  (
    left: [Sichuan Collegiate Programming Contest 2025],
    link: "https://qoj.ac/contest/2152",
    fold: false,
  ),
  (
    left: [Guangxi Collegiate Programming Contest 2025 Invitation],
    link: "https://ac.nowcoder.com/acm/contest/110811",
    fold: false,
  ),
  (
    left: [The 2025 ICPC Asia East Continent Online Contest II],
    link: "https://qoj.ac/contest/2524",
    fold: false,
  ),
)

= isaunoya

#for item in profile-links [
  - #link(item.url)[#text(item.label)]
]

== Problem Setting

#for item in contest-setting [
  - #link(item.link)[#item.left]
]
