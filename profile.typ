#import "/.typst-blog/typst/home.typ": profile-intro, profile-link-section

#let identity = json("typst-blog.config.json").profile

#let contests = (
  (
    date: "2025",
    title: "ICPC Asia East Continent Online Contest II",
    url: "https://qoj.ac/contest/2524",
  ),
  (
    date: "2025",
    title: "Guangxi Collegiate Programming Contest Invitation",
    url: "https://ac.nowcoder.com/acm/contest/110811",
  ),
  (
    date: "2025",
    title: "Sichuan Collegiate Programming Contest",
    url: "https://qoj.ac/contest/2152",
  ),
  (
    date: "2024",
    title: "CCPC Female Onsite",
    url: "https://qoj.ac/contest/1841",
  ),
)

#profile-intro(
  avatar_url: identity.avatar,
  avatar_alt: identity.name,
  avatar_initial: "I",
  links: identity.links,
  show_posts_action: false,
  details: profile-link-section(
    title: "Problem Setting",
    id: "problem-setting",
    items: contests,
  ),
)
