export default function($ = window.jQuery) {

  function setupMobileMenu() {
    const htmlElement = document.getElementsByTagName("html")[0];
    const menuButton = document.querySelector("button.m-menu__toggle");
    const searchButton = document.querySelector("button.header-search__toggle");
    const veil = document.querySelector(".m-menu__cover");
    const header = document.querySelector("header.header");
    const menu = document.querySelector(".m-menu__content");
    const accordions = document.querySelectorAll("accordion-heading");

    const scrollToTop = () => {
      window.setTimeout(() => {
        menu.scrollTop = 0;
      }, 200);
    }

    menuButton.addEventListener("click", () => {
      $(header).toggleClass('menu-open');
      $(htmlElement).toggleClass('modal-open');
      scrollToTop();
    });
    searchButton.addEventListener("click", () => {
      $(header).toggleClass('search-open');
      $(htmlElement).toggleClass('modal-open');
    });

    veil.addEventListener("click", () => {
      $(header).removeClass('menu-open');
      $(header).removeClass('search-open');
      $(htmlElement).removeClass('modal-open');
      scrollToTop();
    })

    document.body.addEventListener("keydown", (e) => {
      if (e.key == 'Escape') {
        $(header).removeClass('menu-open');
        $(header).removeClass('search-open');
        $(htmlElement).removeClass('modal-open');
        scrollToTop();
      }
    })
    

    // Accordion click opens
    accordions.forEach(function(accordion) {
      accordion.addEventListener("click", () => {
        this.classList.toggle("active");
        var panel = this.nextElementSibling;
        console.log(panel.id);
        if (panel.style.display === "block") {
          panel.style.display = "none";
        } else {
          panel.style.display = "block";
        }
      })
    })
  }
    
  document.addEventListener(
    "turbolinks:load",
    () => window.nextTick(setupMobileMenu),
    { passive: true }
  );
}
