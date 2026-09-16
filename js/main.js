(function () {
  const verses = [
    { text: "O Senhor é o meu pastor; nada me faltará.", ref: "Salmos 23:1" },
    { text: "Posso todas as coisas naquele que me fortalece.", ref: "Filipenses 4:13" },
    { text: "Tudo posso naquele que me fortalece. Espera no Senhor, anima-te, e ele fortalecerá o teu coração.", ref: "Salmos 27:14" },
    { text: "Vinde a mim, todos os que estais cansados e oprimidos, e eu vos aliviarei.", ref: "Mateus 11:28" },
    { text: "O justo viverá pela fé.", ref: "Habacuque 2:4" },
    { text: "Deus é amor, e quem permanece no amor permanece em Deus, e Deus nele.", ref: "1 João 4:16" },
    { text: "Entrega o teu caminho ao Senhor; confia nele, e ele tudo fará.", ref: "Salmos 37:5" },
    { text: "Não temas, porque eu sou contigo; não te assombres, porque eu sou o teu Deus.", ref: "Isaías 41:10" },
    { text: "O choro pode durar uma noite, mas a alegria vem pela manhã.", ref: "Salmos 30:5" },
    { text: "Se Deus é por nós, quem será contra nós?", ref: "Romanos 8:31" }
  ];

  const verseEl = document.getElementById("dailyVerse");
  const reflectionEl = document.getElementById("dailyReflection");
  const newVerseBtn = document.getElementById("newVerse");

  const reflections = [
    "Confie no cuidado de Deus para hoje. Ele guia, sustenta e renova as suas forças.",
    "Deixe a ansiedade de lado e descanse na certeza de que Deus já preparou o seu caminho.",
    "A oração abre portas que nenhuma chave consegue abrir. Comece hoje em conversa com Deus.",
    "Mesmo no silêncio, Deus está agindo a seu favor. Não perca a esperança.",
    "A gratidão transforma o que temos em suficiente. Agradeça a Deus hoje.",
    "O amor de Deus não depende dos seus acertos. Ele simplesmente ama você."
  ];

  let last = -1;

  function showVerse() {
    let i = Math.floor(Math.random() * verses.length);
    while (i === last) {
      i = Math.floor(Math.random() * verses.length);
    }
    last = i;
    const v = verses[i];
    verseEl.innerHTML = "<p>" + v.text + "</p><footer>— " + v.ref + "</footer>";
    const r = reflections[Math.floor(Math.random() * reflections.length)];
    reflectionEl.textContent = r;
  }

  if (newVerseBtn) {
    newVerseBtn.addEventListener("click", showVerse);
  }

  showVerse();

  const form = document.getElementById("contactForm");
  if (form) {
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      const btn = form.querySelector("button[type=submit]");
      const old = btn.textContent;
      btn.textContent = "Mensagem enviada!";
      btn.disabled = true;
      form.reset();
      setTimeout(function () {
        btn.textContent = old;
        btn.disabled = false;
      }, 3000);
    });
  }
})();