const admin = require('../firebase');

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  const mockUser = req.headers['x-mock-user'];
  const bypassUid = process.env.AUTH_BYPASS_UID;

  try {
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decoded = await admin.auth().verifyIdToken(token);
      req.user = { uid: decoded.uid, token: decoded };
      return next();
    }

    if (mockUser) {
      req.user = { uid: mockUser, token: null };
      return next();
    }

    if (bypassUid) {
      req.user = { uid: bypassUid, token: null };
      return next();
    }

    return res.status(401).json({ error: 'Auth token obrigatorio.' });
  } catch (err) {
    console.error('authMiddleware erro', err);
    return res.status(401).json({ error: 'Token invalido.' });
  }
}

module.exports = {
  authMiddleware,
};
