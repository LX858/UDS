import { fetchNui } from './fetchNui.js';
import { Global } from '../../lang/global.js';
import config from './config.js';

/**
 * Get element by id
 * @param id {string}
 **/
const getElementById = (id) => document.getElementById(id);

/**
 * Set visibility
 * @param visibility {string}
 **/
const setVisibility = (visibility) => getElementById('um-idcard').style.visibility = visibility;

/**
 * Set visibility of badge
 * @param badge {string|Object|null}
 **/
const setBadgeVisibility = (badge) => {
  const badgeElement = getElementById('badge');
  if (!badge || badge === 'none') {
    badgeElement.style.display = 'none';
    return;
  }
  getElementById('badgeimg').src = `badges/${badge.img}.png`;
  getElementById('badgegrade').textContent = badge.grade;
  badgeElement.style.display = 'flex';
};

const closeFunction = () => {
  getElementById('um-idcard').classList.remove('animate__animated', 'animate__fadeInLeft', 'animate__faster');
  setVisibility('hidden');
  setBadgeVisibility('none');
  fetchNui('closeIdCard');
};

/**
 * Open id card
 * @param playerData {Object}
 **/
const openIdCard = (playerData) => {
  const license = config.licenses[playerData.cardtype];
  const isDriverLicense = playerData.cardtype === 'driver_license';

  let dinhdanhVal = playerData.dinhdanh;
  if (dinhdanhVal === undefined || dinhdanhVal === null || dinhdanhVal === '') {
    dinhdanhVal = 1;
  } else if (typeof dinhdanhVal === 'string') {
    if (dinhdanhVal.includes('2')) {
      dinhdanhVal = 2;
    } else if (dinhdanhVal.includes('1')) {
      dinhdanhVal = 1;
    }
  }

  let ngaycapVal = playerData.ngaycap;
  if (!ngaycapVal) {
    const today = new Date();
    const day = String(today.getDate()).padStart(2, '0');
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const year = today.getFullYear();
    ngaycapVal = `${day}/${month}/${year}`;
  } else if (typeof ngaycapVal === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(ngaycapVal.trim())) {
    const parts = ngaycapVal.trim().split('-');
    ngaycapVal = `${parts[2]}/${parts[1]}/${parts[0]}`;
  }

  const elements = {
    lastname: playerData.lastname,
    name: playerData.firstname,
    sign: `${playerData.lastname} ${playerData.firstname}`,
    dob: playerData.birthdate,
    sex: playerData.sex,
    nationality: isDriverLicense ? playerData.Loaibang : playerData.nationality,
    dinhdanh: dinhdanhVal,
    ngaycap: ngaycapVal,
    cardtype: license.header,
  };
  getElementById('lang_nat').textContent = isDriverLicense ? 'Hạng bằng lái' : 'Quốc tịch';

  Object.entries(elements).forEach(([key, value]) => {
    getElementById(key).textContent = value;
  });

  getElementById('mugshot').src = playerData.mugShot;
  getElementById('smallmugshot').src = playerData.mugShot;
  getElementById('um-idcard').style.backgroundImage = `url(${license.backgroundImage})`;
  getElementById('um-idcard').style.backgroundColor = license.background;
  getElementById('um-idcard').classList.add('animate__animated', 'animate__fadeInLeft', 'animate__faster');
  setBadgeVisibility(playerData.badge);
  setVisibility('visible');
  autoClose();
};

const autoClose = () => {
  if (!config.idCardSettings.autoClose.status) return;
  setTimeout(closeFunction, config.idCardSettings.autoClose.time);
};

window.addEventListener('message', (event) => {
  const { type, playerData, configData } = event.data;
  if (type === 'playerData') {
    openIdCard(playerData);
  } else if (type === 'configData') {
    Object.assign(config, configData);
  }
});

window.addEventListener('load', () => {
  Object.entries(Global).forEach(([key, value]) => {
    getElementById(key).textContent = value;
  });
});

document.addEventListener('keydown', (e) => {
  if (e.key !== config.idCardSettings.closeKey) return;
  closeFunction();
});
