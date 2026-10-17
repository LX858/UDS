import 'reflect-metadata';
import React from 'react';
import App from './App';
import './index.css';
import 'react-toastify/dist/ReactToastify.css';
import {startBrowserApp} from './utils/createApp';
import {registerLogService} from './services/log/logService';
import {ConsoleLogProvider} from './services/log/providers/consoleLogProvider';
import {registerMainService} from './services/app/main/main.service';
import {registerEventsService} from './services/events/events.service';
import {registerBoilerPlateService} from './services/app/boilerplate/boilerplate.service';
import {ServicesContainer} from './utils/servicesContainer';
import {registerConfigService} from './services/config.service';
import { registerGpsService } from './services/app/gps/gps.service';

const start = (
  afterRender?: (container: ServicesContainer) => void | Promise<void>
) => {
  startBrowserApp({
    defineServices: container => {
      // Define services here
      registerLogService(container, [ConsoleLogProvider]);
      registerConfigService(container);
      registerEventsService(container);
      registerMainService(container);
      registerBoilerPlateService(container);
      registerGpsService(container);
    },
    beforeRender: async () => {},
    render: () => (
      <App />
    ),
    afterRender(container) {
      afterRender && afterRender(container);
    },
  });
};

start();

export default start;
