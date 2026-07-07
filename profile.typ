#import "/.typst-blog/typst/home.typ": profile-intro
#import "/.typst-blog/typst/profile.typ" as profile

#let profile-bio = "Hi there! I’m isaunoya."

#let profile-about = "I’m currently focused on competitive programming and AI inference. The sections below collect selected public experience, awards, and problem-setting contributions."

#let profile-links = (
  (label: "GitHub", url: "https://github.com/isaunoya"),
  (label: "Codeforces", url: "https://codeforces.com/profile/Retired_Isaunoya"),
  (label: "Libra", url: "https://isaunoya.github.io/libra/"),
  (label: "Email", url: "mailto:isaunoya@qq.com"),
)

#let experience = (
  profile.row(
    icon: "assets/minimax-preview.png",
    left: [MiniMax - AI Inference],
    right: [Mar.2026 -],
    fold: false,
  ),
)

#let awards = (
  profile.row(
    date: [Apr. 2026],
    left: [11th CCPC Final — Gold Medal, 12th Place],
    link: "https://pintia.cn/rankings/2046522266744168448",
    fold: false,
  ),
  profile.row(
    date: [Nov. 2025],
    left: [11th CCPC Regional Contest (Chongqing) — Gold Medal, 2nd Place],
    link: "https://board.xcpcio.com/ccpc/11th/chongqing",
    fold: false,
  ),
  profile.row(
    date: [Nov. 2025],
    left: [11th CCPC Regional Contest (Harbin) — Gold Medal, 12th Place],
    link: "https://board.xcpcio.com/ccpc/11th/harbin",
    fold: true,
  ),
  profile.row(
    date: [Nov. 2025],
    left: [50th ICPC Asia Regional Contest (Wuhan) — Gold Medal, 25th Place],
    link: "https://board.xcpcio.com/icpc/50th/wuhan",
    fold: true,
  ),
  profile.row(
    date: [Oct. 2025],
    left: [50th ICPC Asia Regional Contest (Xi'an) — Gold Medal, 6th Place],
    link: "https://board.xcpcio.com/icpc/50th/xian",
    fold: false,
  ),
  profile.row(
    date: [Dec. 2024],
    left: [49th ICPC Asia Regional Contest (Hong Kong) — Gold Medal, 4th Place],
    link: "https://board.xcpcio.com/icpc/49th/hongkong",
    fold: false,
  ),
  profile.row(
    date: [Dec. 2024],
    left: [49th ICPC Asia Regional Contest (Kunming) — Gold Medal, 8th Place],
    link: "https://board.xcpcio.com/icpc/49th/kunming",
    fold: true,
  ),
  profile.row(
    date: [Nov. 2024],
    left: [10th CCPC Regional Contest (Zhengzhou) — Gold Medal, 11th Place],
    link: "https://board.xcpcio.com/ccpc/10th/zhengzhou",
    fold: true,
  ),
  profile.row(
    date: [Oct. 2024],
    left: [10th CCPC Regional Contest (Jinan) — Gold Medal, 3rd Place],
    link: "https://board.xcpcio.com/ccpc/10th/jinan",
    fold: false,
  ),
  profile.row(
    date: [May 2024],
    left: [2024 CCPC Invitational Contest (Shandong) — Gold Medal, 1st Place],
    link: "https://board.xcpcio.com/provincial-contest/2024/shandong",
    fold: false,
  ),
  profile.row(
    date: [Apr. 2024],
    left: [21st Zhejiang Provincial Collegiate Programming Contest — Gold Medal, 1st Place],
    link: "https://board.xcpcio.com/provincial-contest/2024/zhejiang",
    fold: false,
  ),
)

#let contest-setting = (
  profile.row(
    left: [2024 China Collegiate Programming Contest (CCPC) Female Onsite],
    link: "https://qoj.ac/contest/1841",
    fold: false,
  ),
  profile.row(
    left: [Sichuan Collegiate Programming Contest 2025],
    link: "https://qoj.ac/contest/2152",
    fold: false,
  ),
  profile.row(
    left: [Guangxi Collegiate Programming Contest 2025 Invitation],
    link: "https://ac.nowcoder.com/acm/contest/110811",
    fold: false,
  ),
  profile.row(
    left: [The 2025 ICPC Asia East Continent Online Contest II],
    link: "https://qoj.ac/contest/2524",
    fold: false,
  ),
)

#let html-profile() = profile-intro(
  bio: profile-bio,
  avatar_url: "https://github.com/isaunoya.png",
  avatar_alt: "Profile avatar",
  avatar_initial: "I",
  posts_url: "posts/",
  links: profile-links,
  show_posts_action: false,
  details: [
    #profile.about(profile-about)
    #profile.section(id: "experience", title: "Experience", rows: experience)
    #profile.section(id: "awards", title: "Awards", rows: awards, size: "small")
    #profile.section(
      id: "problem-setting",
      title: "Problem-setting Contributions",
      rows: contest-setting,
      size: "small",
    )
  ],
)

#let fallback-row-title(item) = {
  if item.link != none and item.link != "" {
    link(item.link)[#item.left]
  } else {
    item.left
  }
}

#let fallback-rows(items) = [
  #for item in items [
    - #if item.date != none {
      text(weight: "bold")[#item.date]
      h(0.5em)
    }#fallback-row-title(item)#if item.right != none {
      [, #item.right]
    }
  ]
]

#let fallback-profile = [
  = isaunoya

  #profile-bio

  #profile-about

  #for item in profile-links [
    #link(item.url)[#text(item.label)]#h(0.65em)
  ]

  = Experience

  #fallback-rows(experience)

  = Awards

  #fallback-rows(awards)

  = Problem-setting Contributions

  #fallback-rows(contest-setting)
]

#context if target() == "html" {
  html-profile()
} else {
  fallback-profile
}
