#import "/.typst-blog/typst/home.typ": profile-intro, profile-link-section

#let identity = json("typst-blog.config.json").profile

#let lectures = (
  (date: "PDF", title: "根号数据结构与根号分治 [AI rewrite]", url: "/assets/lectures/sqrt-decomposition.pdf"),
  (date: "PDF", title: "随机化选讲 [AI rewrite]", url: "/assets/lectures/randomization.pdf"),
)

#let contests = (
  (date: "2025", title: "ICPC Asia East Continent Online Contest II · 部分题目讲评 [AI rewrite]", url: "/assets/editorials/2025-online-2.pdf"),
  (date: "2025", title: "Guangxi Collegiate Programming Contest Invitation · 部分题目讲评 [AI rewrite]", url: "/assets/editorials/2025-guangxi.pdf"),
  (date: "2025", title: "Sichuan Collegiate Programming Contest · 部分题目讲评 [AI rewrite]", url: "/assets/editorials/2025-sichuan.pdf"),
  (date: "2024", title: "CCPC Female Onsite · 部分题目讲评 [AI rewrite]", url: "/assets/editorials/2024-ccpc-women.pdf"),
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
