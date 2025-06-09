import packageInfo from '../package.json';
import env from './env';

const app = {
  version: packageInfo.version,
  name: 'henkin.world',
  logoUrl: '/logo2-hw.png',
  url: env.appUrl,
};

export default app;
