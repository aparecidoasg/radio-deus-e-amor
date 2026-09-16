// ============================================================================
// NAVEGADOR SEGURO WINDOWS 11 ENTERPRISE
// user.js - Configurações de Segurança Extrema
// ============================================================================

// --- BLOQUEIO DE COOKIES E TRACKERS ---
user_pref("network.cookie.cookieBehavior", 1);  // Apenas do servidor solicitador
user_pref("network.cookie.lifetimePolicy", 2);  // Sesão apenas
user_pref("network.cookie.clearOnShutdown", true);  // Limpar cookies ao fechar
user_pref("network.dns.disablePrefetch", true);  // Desabilitar DNS prefetch
user_pref("network.prefetch-controls", 0);  // Desabilitar todos prefetch

--- RASTREIAMENTE E PRIVACIDADE ---
user_pref("privacy.trackingprotection.enabled", true);  // Proteção de rastreamento ativada
user_pref("privacy.trackingprotection.social.enabled", true);  // Bloquear redes sociais
user_pref("privacy.trackingprotection.cryptomining.enabled", true);  // Bloquear crypto mining
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);  // Bloquear fingerprinting
user_pref("privacy.sanitize.migrateFennecPrefs", true);  // Migração de prefs de sanitização
user_pref("privacy.partition.session", true);  // Particionamento de sessão isolado

--- TELEMETRIA E DADOS ---
user_pref("toolkit.telemetry.enabled", false);  // Telemetry desabilitada
user_pref("toolkit.telemetry.unified", false);  // Telemetry unificada desativada
user_pref("toolkit.telemetry.server");  // Sem servidor de telemetry
user_pref("datareporting.healthreport.uploadEnabled", false);  // Healthreport desativado
user_pref("datareporting.sér.importance", 0);  // Desabilitar relatórios de erro
user_pref("datareporting.pingsend", false);  // Desabilitar pings de uso

--- SEGURANÇA DE NAVEGAÇÃO ---
user_pref("browser.safebrowsing.enabled", true);  // Safe Browsing ativado
user_pref("browser.safebrowsing.downloads.remote.enabled", true);  // Downloads protegidos
user_pref("browser.safebrowsing.malware.enabled", true);  // Proteção contra malware
user_pref("browser.safebrowsing.phish.enabled", true);  // Proteção contra phishing

--- HTTPS-ONLY ---
user_pref("network.security.https_only_mode", 2);  // HTTPS-Only mode estrito
user_pref("network.stricttransportsecurity.enabled", true);  // HSTS estrito

--- CONTEÚDO E PLUGINS ---
user_pref("media.peerconnection.enabled", false);  // Desabilitar WebRTC (vazamento de IP)
user_pref("media.peerconnection.use_iceservers", false);  // Desabilitar ICE servers
user_pref("plugins.disabled", true);  // Desabilitar plugins (ex: Flash)
user_pref("ppapi.flash.enabled", false);  // Flash desabilitado
user_pref("media.video_surface", false);  // Desabilhar superfície de vídeo

--- IDENTIFICADOR DE NAVEGADOR ---
user_pref("general.useragent.override");  // User agent vazio/padrão
user_pref("general.platform.override");  // Plataforma override

--- ABASTECIMENTO AUTOMÁTICO ---
user_pref("app.normandy.enabled", false);  // Norma disabled
user_pref("app.shield.opt.outstudies", true);  // Opt-out de studies

--- DESCARGA ---
user_pref("browser.download.manager.skimode", true);  // Modo skim (visual simplificado)
user_pref("browser.download.manager.alertOnEXEOpen", true);  // Alerta ao abrir EXE
user_pref("browser.download.manager.showWhenFinished", true);  // Mostrar quando terminar
user_pref("browser.download.manager.useWindow", false);  // Não abrir janela pop-up

--- HARDENING DE ABOUT:CONFIG ---
user_pref("general.config.allowNow", false);  // Bloquear acesso a about:config via UI
// Nota: about:config ainda acessível digitando about:config na barra, mas configurações acima já aplicam

===========================================================================
// FIM DO user.js
// ============================================================================