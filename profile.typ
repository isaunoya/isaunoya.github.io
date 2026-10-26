#import "/.typst-blog/typst/home.typ": profile-intro, profile-link-section

#let identity = json("typst-blog.config.json").profile

#let lectures = (
  (date: "PDF", title: "根号数据结构与根号分治 [AI rewrite]", url: "/lectures/sqrt-decomposition.pdf"),
  (date: "PDF", title: "随机化选讲 [AI rewrite]", url: "/lectures/randomization.pdf"),
)

#let contests = (
  (date: "2025", title: "ICPC Asia East Continent Online Contest II", url: "https://qoj.ac/contest/2524",
    resource: (title: "题解 PDF [AI rewrite]", url: "/solutions/2025-online-2.pdf")),
  (date: "2025", title: "Guangxi Collegiate Programming Contest Invitation", url: "https://ac.nowcoder.com/acm/contest/110811",
    resource: (title: "题解 PDF [AI rewrite]", url: "/solutions/2025-guangxi.pdf")),
  (date: "2025", title: "Sichuan Collegiate Programming Contest", url: "https://qoj.ac/contest/2152",
    resource: (title: "题解 PDF [AI rewrite]", url: "/solutions/2025-sichuan.pdf")),
  (date: "2024", title: "CCPC Female Onsite", url: "https://qoj.ac/contest/1841",
    resource: (title: "题解 PDF [AI rewrite]", url: "/solutions/2024-ccpc-women.pdf")),
)

#profile-intro(
  avatar_url: identity.avatar,
  avatar_alt: identity.name,
  avatar_initial: "I",
  links: identity.links,
  show_posts_action: false,
  details: [
    #profile-link-section(title: "Lectures", id: "lectures", items: lectures)
    #profile-link-section(title: "Problem Setting", id: "problem-setting", items: contests)
  ],
)
