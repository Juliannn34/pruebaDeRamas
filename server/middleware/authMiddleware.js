const jwt = require('jsonwebtoken');

const COOKIE_NAME = 'vortex_token';

/**
 * Verifica el JWT almacenado en la cookie HTTP-Only.
 * Si es válido, adjunta el payload en req.user.
 */
function authMiddleware(req, res, next) {
  let token = null;

  // 1. Prioridad: Header Authorization: Bearer <token>
  // Fundamental para clientes cross-domain (ej. Vercel -> Render) donde navegadores móviles e incógnito bloquean third-party cookies.
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (authHeader && typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
    token = authHeader.slice(7).trim();
  } else if (req.cookies && req.cookies[COOKIE_NAME]) {
    // 2. Fallback: Cookie HTTP-Only
    token = req.cookies[COOKIE_NAME];
  }

  if (!token) {
    return res.status(401).json({ error: 'No autenticado' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    req.user = { id: payload.sub, correo: payload.correo, nombre: payload.nombre, rol: payload.rol };
    return next();
  } catch {
    return res.status(401).json({ error: 'Sesión inválida o expirada' });
  }
}

module.exports = authMiddleware;
module.exports.COOKIE_NAME = COOKIE_NAME;
