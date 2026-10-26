import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const getItemImageUrl = (itemName, ext) => {
    if (!InventoryHub || !itemName) return ''
    const base = InventoryHub.endsWith('/') ? InventoryHub : (InventoryHub + '/')
    return `${base}${itemName}.${ext}`
  }

  const onItemImgError = (e) => {
    // Tránh nháy do thử nhiều định dạng: nếu lỗi thì dùng ảnh placeholder luôn
    e.currentTarget.onerror = null
    e.currentTarget.src = './images/no-image.png'
  }

  useEffect(() => {
    const handleEvent = (event) => {
      const v = event.data;
      if (v.type == 'FirstLoad') {
        setInventoryHub(v.InventoryHub)
        setDetailServer(v.DetailServer)
        setButtonAcceptEvent(v.ButtonAcceptEvent)
        setDefaultColorStart(v.DefaultColorStart)
        setButtonDeniedEvent(v.ButtonDeniedEvent)
      } else if (v.type == 'OpenMenuAdmin') {
        setOpenMenuAdmin(true)
        setDataItemHudRewards(v.DataItem)
        setDataItemHud(v.DataItem)
        setRewardsMenu(false)
      } else if (v.type == 'UpdateTime') {
        setTimeEvent(v.CountDown)
      } else if (v.type == 'UpdateTeam') {
        setDataTeam(v.DataTeam)
      } else if (v.type == 'UpdateTeamSelect') {
        setSelectTeamName(v.SelectTeamName)
        setSelectTeamColor(v.SelectTeamColor)
        setCountPeopleTeamSelect(v.CountPeopleTeamSelect)
        setDefaultColorTeam(v.DefaultColorTeam)
      } else if (v.type == 'CountPeopleTeam') {
        setCountPeopleTeamSelect(v.CountPeopleTeamSelect)
      } else if (v.type == 'GameStartWaitRegister') {
        setEventStart(true)
        setGameStart(true)
        setTimeEventStart(v.TimeEventStart)
        PlaySound(true, v.Sounds,  v.Volume)
      } else if (v.type == 'CloseGameStartWaitRegister') {
        setEventStart(false)
        PlaySound(false)
      } else if (v.type == 'GameStart') {
        setGameStart(false)
        setEventStart(true)
        setDataTeam(v.DataTeam)
      } else if (v.type == 'CloseGameStart') {
        setGameStart(false)
        setEventStart(false)
        setSelectTeamName(null)
        setSelectTeamColor(null)
        setCountPeopleTeamSelect(null)
        setDefaultColorTeam(null)
      } else if (v.type == 'Victory') {
        setOpenVictory(true)
        setVictoryTeam(v.VictoryTeam)
        setTypeVictory(v.TypeVictory)
        setTypeText(v.TypeText)
        setVictoryTeamColorBG(v.VictoryTeamColorBG)
        setVictoryTeamColor(v.VictoryTeamColor)
        setVictoryTeamScore(v.VictoryTeamScore)
        setVictoryItemReward(v.VictoryItemReward)
      } else if (v.type == 'CloseVictory') {
        setOpenVictory(false)
      } else if (v.type == 'CloseMenuAdmin') {
        setOpenMenuAdmin(false)
        setOpenMenuDataItemRewards(false)
        setOpenMenuDataItem(false)
      } else if (v.type == 'OpenMenuSelectTeam') {
        setOpenMenuSelectTeam(true)
        setDataTeam(v.DataTeam)
      } else if (v.type == 'closeOpen') {
        setOpenMenuAdmin(false)
        setOpenMenuDataItemRewards(false)
        setOpenMenuDataItem(false)
        setOpenMenuSelectTeam(false)
      } else if (v.type == 'SwordDead') {
        setSwordDead(true)
        setSwordDeadSeconds(v.Seconds ?? 0)
      } else if (v.type == 'SwordDeadUpdate') {
        setSwordDeadSeconds(v.Seconds ?? 0)
      } else if (v.type == 'SwordDeadHide') {
        setSwordDead(false)
        setSwordDeadSeconds(0)
      }
      $(document).bind("selectstart", function (event) {
        event.preventDefault();
      });
      document.onkeyup = function (data) {
        if (data.which === 27) {
          $.post('https://Zc_SwordFlag/closex');
          setOpenMenuAdmin(false)
          setOpenMenuDataItemRewards(false)
          setOpenMenuDataItem(false)
          setOpenMenuSelectTeam(false)

        }
      };
    };

    window.addEventListener('message', handleEvent);

    return () => {
      window.removeEventListener('message', handleEvent);
    };
  }, []);

  //////////// First Load Zone ////////////
  const [InventoryHub, setInventoryHub] = useState()
  //////////// Header Zone ////////////
  const [NameEvent, setNameEvent] = useState('Cướp Cờ')
  const [DetailServer, setDetailServer] = useState()
  const [TimeEventStart, setTimeEventStart] = useState()
  const [ButtonAcceptEvent, setButtonAcceptEvent] = useState()
  const [ButtonDeniedEvent, setButtonDeniedEvent] = useState()
  const [TimeEvent, setTimeEvent] = useState()
  const [DefaultColorStart, setDefaultColorStart] = useState('#B50116')
  const [EventStart, setEventStart] = useState(false)
  const [GameStart, setGameStart] = useState(false)
  //////////// MenuSelectTeam Zone ////////////
  const [SelectTeamName, setSelectTeamName] = useState(null)
  const [SelectTeamColor, setSelectTeamColor] = useState(null)
  const [CountPeopleTeamSelect, setCountPeopleTeamSelect] = useState(0)
  const [DefaultColorTeam, setDefaultColorTeam] = useState(null)
  const [DataTeam, setDataTeam] = useState([
    // { TeamName: 'Red Team', CountPeople: 12, ColorTeam: '#D2132A', ScoreTeam: 120, ColorBG: 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(210, 19, 42, 0.75) 100%)', PicTeam: 'https://cdn.discordapp.com/attachments/697404744460795936/1168816455186403358/image.webp?ex=65532426&is=6540af26&hm=fc7e313a6d5cac52b6df42220345f92099fcbdf478dae3648e798fa3f579cd56&', ColorBGSelect: 'linear-gradient(90deg, rgba(210, 19, 42, 0.00) 0%, rgba(210, 19, 42, 0.75) 49.48%, rgba(210, 19, 42, 0.00) 100%)', ColorSelect: 'rgba(210, 19, 42, 0.5)', Buff: [{ Scorex2: 0 }, { Scorex3: 15 }, { MinusScore: 10 }] },
    // { TeamName: 'Blue Team', CountPeople: 12, ColorTeam: '#233FFF', ScoreTeam: 100, ColorBG: 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(35, 63, 255, 1) 100%)', PicTeam: 'https://cdn.discordapp.com/attachments/697404744460795936/1168816455186403358/image.webp?ex=65532426&is=6540af26&hm=fc7e313a6d5cac52b6df42220345f92099fcbdf478dae3648e798fa3f579cd56&', ColorBGSelect: 'linear-gradient(90deg, rgba(35, 63, 255, 0.00) 0%, rgba(35, 63, 255, 0.75) 49.48%, rgba(35, 63, 255, 0.00) 100%)', ColorSelect: 'rgba(35, 63, 255, 0.5)', Buff: [{ Scorex2: 10 }, { Scorex3: 0 }, { MinusScore: 0 }] },
  ])
  const [OpenMenuSelectTeam, setOpenMenuSelectTeam] = useState(false)

  //////////// Victory Zone ////////////
  const [OpenVictory, setOpenVictory] = useState(false)
  const [TypeText, setTypeText] = useState()
  const [TypeVictory, setTypeVictory] = useState()
  const [VictoryTeam, setVictoryTeam] = useState()
  const [VictoryTeamColorBG, setVictoryTeamColorBG] = useState('linear-gradient(90deg, rgba(210, 19, 42, 0.38) 0%, rgba(210, 19, 42, 0.05) 50%, rgba(210, 19, 42, 0.38) 100%), rgba(0, 0, 0, 0.50)')
  const [VictoryTeamColor, setVictoryTeamColor] = useState('#D2132A')
  const [VictoryTeamScore, setVictoryTeamScore] = useState(120)
  const [VictoryItemReward, setVictoryItemReward] = useState([
    // { name: 'https://cdn.discordapp.com/attachments/891381989050032228/1165666307937681440/metal-rusty.webp?ex=6550e8d8&is=653e73d8&hm=526f1f7ec762bc29c23eaa43ee64912dec1b363f015a1ae57bbe738579644b7c&' },
    // { name: 'https://cdn.discordapp.com/attachments/989384587652239360/1169863758827491401/box-mine.webp?ex=6556f387&is=65447e87&hm=b27a092457eafa1341ea133510a458ec833512a08617f64114705e05d70ce9bb&' },
  ])
  //////////// Admin Zone ////////////
  const [OpenMenuAdmin, setOpenMenuAdmin] = useState(false)
  const [DateAndTime, setDateAndTime] = useState(new Date().toLocaleString());
  const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const [GetDay, setGetDay] = useState(new Date().getDay());
  const [InputHour, setInputHour] = useState(23)
  const [InputMinute, setInputMinute] = useState(0)
  const [InputTimeEvent, setInputTimeEvent] = useState(10)
  const [TypeGamePlay, setTypeGamePlay] = useState(0)
  const [BoolStartGame, setBoolStartGame] = useState(true)
  const [RewardsMenu, setRewardsMenu] = useState(false)
  const [CountTeamToPlayer, setCountTeamToPlayer] = useState(2)
  const [searchText, setSearchText] = useState('');

  const [DataItemHudRewards, setDataItemHudRewards] = useState([
    // { name: 'https://cdn.discordapp.com/attachments/891381989050032228/1165666307937681440/metal-rusty.webp?ex=6550e8d8&is=653e73d8&hm=526f1f7ec762bc29c23eaa43ee64912dec1b363f015a1ae57bbe738579644b7c&' },
    // { name: 'https://cdn.discordapp.com/attachments/989384587652239360/1169863758827491401/box-mine.webp?ex=6556f387&is=65447e87&hm=b27a092457eafa1341ea133510a458ec833512a08617f64114705e05d70ce9bb&' },
  ])
  const [DataItemHud, setDataItemHud] = useState([
    // { name: 'https://cdn.discordapp.com/attachments/891381989050032228/1165666307937681440/metal-rusty.webp?ex=6550e8d8&is=653e73d8&hm=526f1f7ec762bc29c23eaa43ee64912dec1b363f015a1ae57bbe738579644b7c&' },
    // { name: 'https://cdn.discordapp.com/attachments/989384587652239360/1169863758827491401/box-mine.webp?ex=6556f387&is=65447e87&hm=b27a092457eafa1341ea133510a458ec833512a08617f64114705e05d70ce9bb&' },
  ])
  const [DataItemSelectRewards, setDataItemSelectRewards] = useState([])
  const [DataItemSelect, setDataItemSelect] = useState([])
  const [OpenMenuDataItemRewards, setOpenMenuDataItemRewards] = useState(false)
  const [OpenMenuDataItem, setOpenMenuDataItem] = useState(false)

  //////////// SwordFlag Death UI ////////////
  const [SwordDead, setSwordDead] = useState(false)
  const [SwordDeadSeconds, setSwordDeadSeconds] = useState(0)

  useEffect(() => {
    const intervalID = setInterval(() => {
      setDateAndTime(new Date().toLocaleString());
    }, 1000);

    return () => {
      clearInterval(intervalID);
    };
  }, []);

  useEffect(() => {
    $.post('https://Zc_SwordFlag/Ready', "");
  }, []);
  //////////// Function Zone ////////////

  const CheckHourAndMinute = (e, t) => {
    e = parseInt(e)
    if (t == 'hour') {
      if (e > 23) {
        setInputHour(23)
      } else if (e < 0) {
        setInputHour(0)
      } else {
        setInputHour(e)
      }
    } else if (t == 'minute') {
      if (e > 59) {
        setInputMinute(59)
      } else if (e < 0) {
        setInputMinute(0)
      } else {
        setInputMinute(e)
      }
    } else if (t == 'timeevent') {
      if (e > 60) {
        setInputTimeEvent(60)
      } else if (e < 0) {
        setInputTimeEvent(0)
      } else {
        setInputTimeEvent(e)
      }
    } else if (t == 'count') {
      if (e < 2) {
        setCountTeamToPlayer(2)
      } else {
        setCountTeamToPlayer(e)
      }
    }
  }

  const CharGerPage = () => {
    if (TypeGamePlay == 0) {
      return
    }
    if (RewardsMenu) {
      setRewardsMenu(false)
      setTypeGamePlay(0)
    } else {
      setRewardsMenu(true)
    }
  }
  function SelectTeam(numberTeam, TeamName, TeamColor, CountPeopleTeam, DefaultColorTeamSelect) {
    if (SelectTeamName === null && SelectTeamColor === null) {
      // setSelectTeamName(TeamName)
      // setSelectTeamColor(TeamColor)
      // setCountPeopleTeamSelect(CountPeopleTeam)
      // setDefaultColorTeam(DefaultColorTeamSelect)
      $.post('https://Zc_SwordFlag/SelectTeam', JSON.stringify({
        numberTeam: numberTeam,
      }));
    }
  }
  function AddItemRewards(data) {
    const newItem = {
      name: data.name,
      count: 1,
    }
    setDataItemSelectRewards([...DataItemSelectRewards, newItem]);
    const updatedCart = DataItemHudRewards.filter((item) => item.name !== data.name);
    setDataItemHudRewards(updatedCart);
  }
  function DeleteItemSelect(data) {
    const newItem = {
      name: data.name,
    }
    setDataItemHudRewards([...DataItemHudRewards, newItem]);
    const updatedCart = DataItemSelectRewards.filter((item) => item.name !== data.name);
    setDataItemSelectRewards(updatedCart);
  }
  function AddItem(data) {
    const newItem = {
      name: data.name,
      count: 1,
    }
    setDataItemSelect([...DataItemSelect, newItem]);
    const updatedCart = DataItemHud.filter((item) => item.name !== data.name);
    setDataItemHud(updatedCart);
  }
  function DeleteItem(data) {
    const newItem = {
      name: data.name,
    }
    setDataItemHud([...DataItemHud, newItem]);
    const updatedCart = DataItemSelect.filter((item) => item.name !== data.name);
    setDataItemSelect(updatedCart);
  }
  const AddCountItem = (Count, data) => {
    const newItem = {
      name: data.name,
      count: Count,
    }
    const updatedCart = DataItemSelect.map((item) => {
      if (item.name === data.name) {
        return newItem;
      }
      return item;
    });
    setDataItemSelect(updatedCart);
  }
  const AddCountItemRewards = (Count, data) => {
    const newItem = {
      name: data.name,
      count: Count,
    }
    const updatedCart = DataItemSelectRewards.map((item) => {
      if (item.name === data.name) {
        return newItem;
      }
      return item;
    });
    setDataItemSelectRewards(updatedCart);
  }
  var add = null;
  function PlaySound(typeRun, sound, volume) {
    if (add !== null) {
      add.pause();
    }
    add = new Audio('./assets/' + sound);
    if (typeRun == true) {
      add.volume = volume;
      add.play();
    } 
  }
  function StarGame() {
    $.post('https://Zc_SwordFlag/StarGame', JSON.stringify({
      TypeGamePlay: TypeGamePlay,
      TimeEvent: InputTimeEvent,
      TimeStart: `${InputHour}:${InputMinute}`,
      DataItemSelect: DataItemSelect,
      DataItemSelectRewards: DataItemSelectRewards,
      CountTeamToPlayer: CountTeamToPlayer,
      BoolStartGame: BoolStartGame,
    }));
    setOpenMenuAdmin(false)
    setTypeGamePlay(0)
    setTimeEvent()
    setInputHour(23)
    setInputMinute(0)
    setDataItemSelect([])
    setDataItemSelectRewards([])
    setCountTeamToPlayer(2)
  }
  return (
    <div className="container">
      {
        SwordDead ?
          <div className="sword-death-screen">
            <div className="sword-death-card">
              <div className="sword-death-title">BẠN ĐÃ CHẾT</div>
              <div className="sword-death-sub">Đang chờ hồi sinh tự động trong sự kiện Cướp Cờ</div>
              <div className="sword-death-timer">
                <span className="sword-death-seconds">{SwordDeadSeconds}</span>
                <span className="sword-death-s">s</span>
              </div>
              <div className="sword-death-hint">Không thể về viện trong sự kiện</div>
            </div>
          </div>
          : null
      }
      {
        EventStart ?
          GameStart ?
            <div className="box-top-start-event-sword-center">
              <div className="box-top-start-event-sword">
                <div className="box-top-start-event-bg">
                  <div className="box-top-start-event-scop-box">
                    <div className="box-top-start-event-icon" style={{ background: 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(0, 0, 0, 0.25) 100%)' }}>
                      <svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56" fill="none">
                        <rect width="56" height="56" rx="8" fill="url(#paint0_linear_814_8903)" fill-opacity="0.5" />
                        <path d="M43.9332 11H37.3919C37.227 11.0014 37.0644 11.0387 36.9153 11.1093C36.7663 11.1799 36.6344 11.2821 36.5289 11.4088L19.5512 31.5776L17.4844 29.4994C17.2705 29.2855 16.9805 29.1654 16.6781 29.1654C16.3757 29.1654 16.0856 29.2855 15.8718 29.4994C15.6579 29.7132 15.5378 30.0033 15.5378 30.3057C15.5378 30.6081 15.6579 30.8981 15.8718 31.112L18.0068 33.247L12.5785 38.6639C12.2608 38.9804 12.0088 39.3565 11.8369 39.7706C11.6649 40.1847 11.5764 40.6287 11.5764 41.0771C11.5764 41.5255 11.6649 41.9695 11.8369 42.3836C12.0088 42.7977 12.2608 43.1738 12.5785 43.4903C12.895 43.8079 13.2711 44.0599 13.6852 44.2319C14.0993 44.4038 14.5433 44.4924 14.9917 44.4924C15.4401 44.4924 15.884 44.4038 16.2982 44.2319C16.7123 44.0599 17.0884 43.8079 17.4049 43.4903L22.8218 38.062L24.9568 40.197C25.0624 40.3034 25.188 40.3879 25.3264 40.4456C25.4647 40.5032 25.6132 40.5329 25.7631 40.5329C25.913 40.5329 26.0614 40.5032 26.1998 40.4456C26.3382 40.3879 26.4638 40.3034 26.5694 40.197C26.6758 40.0914 26.7603 39.9658 26.818 39.8274C26.8756 39.6891 26.9053 39.5406 26.9053 39.3907C26.9053 39.2408 26.8756 39.0924 26.818 38.954C26.7603 38.8156 26.6758 38.69 26.5694 38.5844L24.4912 36.5176L44.66 19.5399C44.7867 19.4344 44.8889 19.3025 44.9595 19.1534C45.0301 19.0044 45.0674 18.8418 45.0688 18.6768V12.1356C45.0688 11.8344 44.9491 11.5456 44.7362 11.3326C44.5232 11.1196 44.2343 11 43.9332 11Z" fill="#B50116" />
                        <path d="M26.5468 19.7216L19.5399 11.4088C19.4344 11.2821 19.3025 11.1799 19.1535 11.1093C19.0044 11.0387 18.8418 11.0014 18.6768 11H12.1356C11.8344 11 11.5456 11.1196 11.3326 11.3326C11.1196 11.5456 11 11.8344 11 12.1356V18.6768C11.0014 18.8418 11.0387 19.0044 11.1093 19.1535C11.1799 19.3025 11.2821 19.4344 11.4088 19.5399L20.3576 27.0805L26.5468 19.7216Z" fill={DefaultColorStart} />
                        <path d="M38.0621 33.247L40.1971 31.112C40.411 30.8981 40.5311 30.6081 40.5311 30.3057C40.5311 30.0033 40.411 29.7132 40.1971 29.4994C39.9833 29.2855 39.6932 29.1654 39.3908 29.1654C39.0884 29.1654 38.7984 29.2855 38.5845 29.4994L36.5177 31.5776L35.382 30.283L29.7039 35.0299L31.4755 36.5176L29.3973 38.5844C29.2908 38.69 29.2064 38.8156 29.1487 38.954C29.0911 39.0924 29.0614 39.2408 29.0614 39.3907C29.0614 39.5406 29.0911 39.6891 29.1487 39.8274C29.2064 39.9658 29.2908 40.0914 29.3973 40.197C29.5029 40.3034 29.6285 40.3879 29.7668 40.4456C29.9052 40.5032 30.0537 40.5329 30.2036 40.5329C30.3535 40.5329 30.5019 40.5032 30.6403 40.4456C30.7787 40.3879 30.9043 40.3034 31.0099 40.197L33.1449 38.062L38.5618 43.4903C39.2018 44.1303 40.0699 44.4899 40.975 44.4899C41.8801 44.4899 42.7482 44.1303 43.3882 43.4903C44.0283 42.8503 44.3878 41.9822 44.3878 41.0771C44.3878 40.172 44.0283 39.3039 43.3882 38.6639L38.0621 33.247Z" fill="#B50116" />
                      </svg>
                    </div>
                    <div className="box-top-start-event-text">
                      <p className='DetailServer'>{DetailServer} {TimeEventStart}</p>
                      <p className='NameEvent'>
                        <svg xmlns="http://www.w3.org/2000/svg" width="4" height="4" viewBox="0 0 4 4" fill="none">
                          <circle cx="2" cy="2" r="2" fill="white" />
                        </svg>
                        {NameEvent}
                        <svg xmlns="http://www.w3.org/2000/svg" width="4" height="4" viewBox="0 0 4 4" fill="none">
                          <circle cx="2" cy="2" r="2" fill="white" />
                        </svg>
                      </p>
                      <p className='box-button-accept-event'>Nhấn <span>{ButtonAcceptEvent}</span> Tham Gia | Nhấn <span>{ButtonDeniedEvent}</span> Từ Chối  </p>
                    </div>
                    <div className="box-top-start-event-timer" style={{ background: 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(0, 0, 0, 0.25) 100%)' }}>
                      <p className='Start-In'>Bắt đầu sau</p>
                      <p className='TimeEvent'>{TimeEvent}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            :
            <div className="box-top-start-event-sword-all">
              <div className="box-top-start-event-sword-show-scop-team-left-side">
                {
                  Object.values(DataTeam).map((v, i) => {
                    if (i % 2 !== 0) {
                      return (
                        <>
                        <div className="box-top-start-event-sword-show-ui-box" key={v?.TeamName ?? i}>
                            <div className="box-top-start-event-sword-show-ui-box-top-side">
                              <div className="box-top-start-event-sword-show-ui-box-top-side-scop">
                                <div className="box-top-start-event-sword-show-ui-box-top-side-scop-icon">
                                  <svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56" fill="none">
                                    <rect width="56" height="56" rx="8" fill="url(#paint0_linear_943_2616)" fill-opacity="0.5" />
                                    <path d="M43.9331 11H37.3919C37.227 11.0014 37.0644 11.0387 36.9153 11.1093C36.7663 11.1799 36.6344 11.2821 36.5288 11.4088L19.5512 31.5776L17.4844 29.4994C17.2705 29.2855 16.9805 29.1654 16.6781 29.1654C16.3756 29.1654 16.0856 29.2855 15.8718 29.4994C15.6579 29.7132 15.5378 30.0033 15.5378 30.3057C15.5378 30.6081 15.6579 30.8981 15.8718 31.112L18.0068 33.247L12.5784 38.6639C12.2608 38.9804 12.0088 39.3565 11.8369 39.7706C11.6649 40.1847 11.5764 40.6287 11.5764 41.0771C11.5764 41.5255 11.6649 41.9695 11.8369 42.3836C12.0088 42.7977 12.2608 43.1738 12.5784 43.4903C12.895 43.8079 13.2711 44.0599 13.6852 44.2319C14.0993 44.4038 14.5433 44.4924 14.9917 44.4924C15.4401 44.4924 15.884 44.4038 16.2981 44.2319C16.7123 44.0599 17.0884 43.8079 17.4049 43.4903L22.8218 38.062L24.9568 40.197C25.0624 40.3034 25.188 40.3879 25.3264 40.4456C25.4647 40.5032 25.6132 40.5329 25.7631 40.5329C25.913 40.5329 26.0614 40.5032 26.1998 40.4456C26.3382 40.3879 26.4638 40.3034 26.5694 40.197C26.6758 40.0914 26.7603 39.9658 26.818 39.8274C26.8756 39.6891 26.9053 39.5406 26.9053 39.3907C26.9053 39.2408 26.8756 39.0924 26.818 38.954C26.7603 38.8156 26.6758 38.69 26.5694 38.5844L24.4912 36.5176L44.6599 19.5399C44.7867 19.4344 44.8889 19.3025 44.9595 19.1534C45.0301 19.0044 45.0674 18.8418 45.0688 18.6768V12.1356C45.0688 11.8344 44.9491 11.5456 44.7362 11.3326C44.5232 11.1196 44.2343 11 43.9331 11Z" fill={v.ColorTeam} />
                                    <path d="M26.5468 19.7216L19.5399 11.4088C19.4344 11.2821 19.3025 11.1799 19.1535 11.1093C19.0044 11.0387 18.8418 11.0014 18.6768 11H12.1356C11.8344 11 11.5456 11.1196 11.3326 11.3326C11.1196 11.5456 11 11.8344 11 12.1356V18.6768C11.0014 18.8418 11.0387 19.0044 11.1093 19.1535C11.1799 19.3025 11.2821 19.4344 11.4088 19.5399L20.3576 27.0805L26.5468 19.7216Z" fill={v.ColorTeam} />
                                    <path d="M38.0621 33.2466L40.1971 31.1116C40.411 30.8978 40.5311 30.6077 40.5311 30.3053C40.5311 30.0029 40.411 29.7129 40.1971 29.499C39.9833 29.2852 39.6932 29.165 39.3908 29.165C39.0884 29.165 38.7984 29.2852 38.5845 29.499L36.5177 31.5772L35.382 30.2826L29.7039 35.0295L31.4755 36.5172L29.3973 38.584C29.2908 38.6896 29.2064 38.8152 29.1487 38.9536C29.0911 39.092 29.0614 39.2404 29.0614 39.3903C29.0614 39.5403 29.0911 39.6887 29.1487 39.8271C29.2064 39.9655 29.2908 40.0911 29.3973 40.1966C29.5029 40.3031 29.6285 40.3876 29.7668 40.4452C29.9052 40.5029 30.0537 40.5326 30.2036 40.5326C30.3535 40.5326 30.5019 40.5029 30.6403 40.4452C30.7787 40.3876 30.9043 40.3031 31.0099 40.1966L33.1449 38.0617L38.5618 43.49C39.2018 44.13 40.0699 44.4895 40.975 44.4895C41.8801 44.4895 42.7482 44.13 43.3882 43.49C44.0283 42.8499 44.3878 41.9819 44.3878 41.0767C44.3878 40.1716 44.0283 39.3036 43.3882 38.6635L38.0621 33.2466Z" fill={v.ColorTeam} />
                                    <defs>
                                      <linearGradient id="paint0_linear_943_2616" x1="28" y1="0" x2="28" y2="56" gradientUnits="userSpaceOnUse">
                                        <stop />
                                        <stop offset="1" stop-opacity="0.5" />
                                      </linearGradient>
                                    </defs>
                                  </svg>
                                </div>
                                <div className="box-top-start-event-sword-show-ui-box-top-side-scop-score-team">
                                  <p className='Score'>Điểm</p>
                                  <p className='ScoreTeam'>{v.ScoreTeam}</p>
                                </div>
                              </div>
                            </div>
                            <div className="box-top-start-event-sword-show-ui-box-bottom-side">
                              <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop">
                                {
                                  v.Buff > 1 ?
                                    <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff">
                                      <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff-icon">
                                        <p>{v.Buff == 2 ? 'x2' : 'x3'}</p>
                                      </div>
                                    </div>
                                    : v.Minus > 1 ?
                                      <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff">
                                        <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff-icon">
                                          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none">
                                              <path d="M22.1401 20.7005C21.2301 22.2105 20.0801 21.7305 19.0001 21.0905C17.9201 20.4505 16.9001 19.6805 16.2501 20.5905C15.5401 21.3705 16.0901 22.6205 16.3701 23.7205C16.6501 24.8305 16.6701 25.7905 14.9001 26.0005C13.5001 25.8105 13.5801 24.6505 13.8101 23.4205C14.0401 22.1905 14.4001 20.8905 13.5001 20.4305C12.7801 19.9505 12.2801 20.7805 11.6501 21.6005C11.0001 22.4105 10.2601 23.2005 9.04008 22.6205C7.94008 21.7105 8.36008 21.1805 8.94008 20.5005C9.52008 19.8205 10.2701 18.9105 9.84008 17.3105C9.66008 16.6605 8.76008 16.8105 7.87008 16.7905C7.00008 16.7705 6.12008 16.5905 6.03008 15.2905C5.96008 14.5005 6.55008 14.1805 7.16008 13.9305C7.78008 13.6805 8.41008 13.5005 8.42008 12.8705C8.45008 12.2605 8.04008 11.8305 7.78008 11.3805C7.52008 10.9305 7.41008 10.4605 8.03008 9.76046C9.08008 8.90046 9.92008 9.63046 10.7601 10.4205C11.6001 11.2105 12.4301 12.0405 13.4601 11.3905C14.2801 10.8505 13.5301 9.90046 12.9501 8.97046C12.3701 8.04046 11.9601 7.15046 13.4601 6.74046C14.7601 6.38046 15.2601 7.27046 15.7101 8.30046C16.1701 9.33046 16.5701 10.5005 17.6701 10.7105C19.2401 11.0005 20.3801 9.16046 21.4701 7.70046C22.5601 6.24046 23.6301 5.15046 25.0001 6.95046C26.5001 8.84046 25.0701 9.72046 23.4001 10.5005C21.7301 11.2305 19.8101 11.8705 20.2701 13.2805C20.5401 14.1005 21.4201 13.6505 22.3501 13.3405C23.2701 13.0305 24.2601 12.8605 24.7401 14.2705C25.2501 15.7605 24.0401 16.1005 22.6801 16.2405C21.3201 16.3805 19.8001 16.3205 19.7001 17.0005C19.5901 17.7105 20.5001 18.0005 21.2901 18.4205C22.0801 18.8505 22.7501 19.4205 22.1401 20.7005ZM24.5001 23.0005C23.5501 23.0005 23.0601 22.2605 23.0601 21.5005C23.0601 20.7405 23.5401 20.0005 24.5001 20.0005C25.5001 20.0005 26.0001 20.7405 26.0001 21.5005C26.0001 22.2605 25.5001 23.0005 24.5001 23.0005Z" fill="url(#paint1_linear_815_18563)" />
                                              <defs>
                                                <linearGradient id="paint0_linear_815_18563" x1="16" y1="0" x2="16" y2="32" gradientUnits="userSpaceOnUse">
                                                  <stop />
                                                  <stop offset="1" stop-opacity="0.5" />
                                                </linearGradient>
                                                <linearGradient id="paint1_linear_815_18563" x1="16.0122" y1="6.01172" x2="16.0122" y2="26.0005" gradientUnits="userSpaceOnUse">
                                                  <stop stop-color={DefaultColorStart} />
                                                  <stop offset="1" stop-color={DefaultColorStart} stop-opacity="0.25" />
                                                </linearGradient>
                                              </defs>
                                            </svg>
                                          </svg>
                                        </div>
                                      </div>
                                      : null
                                }


                              </div>
                            </div>
                          </div>
                        </>
                      )
                    }
                    return null;
                  })
                }
              </div>
              <div className="box-top-start-event-sword">
                <div className="box-top-start-event-bg">
                  <div className="box-top-start-event-scop-box">
                    <div className="box-top-start-event-icon" style={{ background: 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(0, 0, 0, 0.25) 100%)' }}>
                      <svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56" fill="none">
                        <rect width="56" height="56" rx="8" fill="url(#paint0_linear_814_8903)" fill-opacity="0.5" />
                        <path d="M43.9332 11H37.3919C37.227 11.0014 37.0644 11.0387 36.9153 11.1093C36.7663 11.1799 36.6344 11.2821 36.5289 11.4088L19.5512 31.5776L17.4844 29.4994C17.2705 29.2855 16.9805 29.1654 16.6781 29.1654C16.3757 29.1654 16.0856 29.2855 15.8718 29.4994C15.6579 29.7132 15.5378 30.0033 15.5378 30.3057C15.5378 30.6081 15.6579 30.8981 15.8718 31.112L18.0068 33.247L12.5785 38.6639C12.2608 38.9804 12.0088 39.3565 11.8369 39.7706C11.6649 40.1847 11.5764 40.6287 11.5764 41.0771C11.5764 41.5255 11.6649 41.9695 11.8369 42.3836C12.0088 42.7977 12.2608 43.1738 12.5785 43.4903C12.895 43.8079 13.2711 44.0599 13.6852 44.2319C14.0993 44.4038 14.5433 44.4924 14.9917 44.4924C15.4401 44.4924 15.884 44.4038 16.2982 44.2319C16.7123 44.0599 17.0884 43.8079 17.4049 43.4903L22.8218 38.062L24.9568 40.197C25.0624 40.3034 25.188 40.3879 25.3264 40.4456C25.4647 40.5032 25.6132 40.5329 25.7631 40.5329C25.913 40.5329 26.0614 40.5032 26.1998 40.4456C26.3382 40.3879 26.4638 40.3034 26.5694 40.197C26.6758 40.0914 26.7603 39.9658 26.818 39.8274C26.8756 39.6891 26.9053 39.5406 26.9053 39.3907C26.9053 39.2408 26.8756 39.0924 26.818 38.954C26.7603 38.8156 26.6758 38.69 26.5694 38.5844L24.4912 36.5176L44.66 19.5399C44.7867 19.4344 44.8889 19.3025 44.9595 19.1534C45.0301 19.0044 45.0674 18.8418 45.0688 18.6768V12.1356C45.0688 11.8344 44.9491 11.5456 44.7362 11.3326C44.5232 11.1196 44.2343 11 43.9332 11Z" fill="#B50116" />
                        <path d="M26.5468 19.7216L19.5399 11.4088C19.4344 11.2821 19.3025 11.1799 19.1535 11.1093C19.0044 11.0387 18.8418 11.0014 18.6768 11H12.1356C11.8344 11 11.5456 11.1196 11.3326 11.3326C11.1196 11.5456 11 11.8344 11 12.1356V18.6768C11.0014 18.8418 11.0387 19.0044 11.1093 19.1535C11.1799 19.3025 11.2821 19.4344 11.4088 19.5399L20.3576 27.0805L26.5468 19.7216Z" fill={DefaultColorStart} />
                        <path d="M38.0621 33.247L40.1971 31.112C40.411 30.8981 40.5311 30.6081 40.5311 30.3057C40.5311 30.0033 40.411 29.7132 40.1971 29.4994C39.9833 29.2855 39.6932 29.1654 39.3908 29.1654C39.0884 29.1654 38.7984 29.2855 38.5845 29.4994L36.5177 31.5776L35.382 30.283L29.7039 35.0299L31.4755 36.5176L29.3973 38.5844C29.2908 38.69 29.2064 38.8156 29.1487 38.954C29.0911 39.0924 29.0614 39.2408 29.0614 39.3907C29.0614 39.5406 29.0911 39.6891 29.1487 39.8274C29.2064 39.9658 29.2908 40.0914 29.3973 40.197C29.5029 40.3034 29.6285 40.3879 29.7668 40.4456C29.9052 40.5032 30.0537 40.5329 30.2036 40.5329C30.3535 40.5329 30.5019 40.5032 30.6403 40.4456C30.7787 40.3879 30.9043 40.3034 31.0099 40.197L33.1449 38.062L38.5618 43.4903C39.2018 44.1303 40.0699 44.4899 40.975 44.4899C41.8801 44.4899 42.7482 44.1303 43.3882 43.4903C44.0283 42.8503 44.3878 41.9822 44.3878 41.0771C44.3878 40.172 44.0283 39.3039 43.3882 38.6639L38.0621 33.247Z" fill="#B50116" />
                      </svg>
                    </div>
                    <div className="box-top-start-event-text">
                      <p className='DetailServer'>{DetailServer} {TimeEventStart}</p>
                      <p className='NameEvent'>
                        <svg xmlns="http://www.w3.org/2000/svg" width="4" height="4" viewBox="0 0 4 4" fill="none">
                          <circle cx="2" cy="2" r="2" fill="white" />
                        </svg>
                        {NameEvent}
                        <svg xmlns="http://www.w3.org/2000/svg" width="4" height="4" viewBox="0 0 4 4" fill="none">
                          <circle cx="2" cy="2" r="2" fill="white" />
                        </svg>
                      </p>
                    </div>
                    <div className="box-top-start-event-timer" style={{ background: 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(0, 0, 0, 0.25) 100%)' }}>
                      <p className='Start-In'>Kết thúc</p>
                      <p className='TimeEvent'>{TimeEvent}</p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="box-top-start-event-sword-show-scop-team-right-side">
                {
                  Object.values(DataTeam).map((v, i) => {
                    if (i % 2 === 0) {
                      return (
                        <>
                        <div className="box-top-start-event-sword-show-ui-box" key={v?.TeamName ?? i}>
                            <div className="box-top-start-event-sword-show-ui-box-top-side">
                              <div className="box-top-start-event-sword-show-ui-box-top-side-scop">
                                <div className="box-top-start-event-sword-show-ui-box-top-side-scop-icon">
                                  <svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56" fill="none">
                                    <rect width="56" height="56" rx="8" fill="url(#paint0_linear_943_2616)" fill-opacity="0.5" />
                                    <path d="M43.9331 11H37.3919C37.227 11.0014 37.0644 11.0387 36.9153 11.1093C36.7663 11.1799 36.6344 11.2821 36.5288 11.4088L19.5512 31.5776L17.4844 29.4994C17.2705 29.2855 16.9805 29.1654 16.6781 29.1654C16.3756 29.1654 16.0856 29.2855 15.8718 29.4994C15.6579 29.7132 15.5378 30.0033 15.5378 30.3057C15.5378 30.6081 15.6579 30.8981 15.8718 31.112L18.0068 33.247L12.5784 38.6639C12.2608 38.9804 12.0088 39.3565 11.8369 39.7706C11.6649 40.1847 11.5764 40.6287 11.5764 41.0771C11.5764 41.5255 11.6649 41.9695 11.8369 42.3836C12.0088 42.7977 12.2608 43.1738 12.5784 43.4903C12.895 43.8079 13.2711 44.0599 13.6852 44.2319C14.0993 44.4038 14.5433 44.4924 14.9917 44.4924C15.4401 44.4924 15.884 44.4038 16.2981 44.2319C16.7123 44.0599 17.0884 43.8079 17.4049 43.4903L22.8218 38.062L24.9568 40.197C25.0624 40.3034 25.188 40.3879 25.3264 40.4456C25.4647 40.5032 25.6132 40.5329 25.7631 40.5329C25.913 40.5329 26.0614 40.5032 26.1998 40.4456C26.3382 40.3879 26.4638 40.3034 26.5694 40.197C26.6758 40.0914 26.7603 39.9658 26.818 39.8274C26.8756 39.6891 26.9053 39.5406 26.9053 39.3907C26.9053 39.2408 26.8756 39.0924 26.818 38.954C26.7603 38.8156 26.6758 38.69 26.5694 38.5844L24.4912 36.5176L44.6599 19.5399C44.7867 19.4344 44.8889 19.3025 44.9595 19.1534C45.0301 19.0044 45.0674 18.8418 45.0688 18.6768V12.1356C45.0688 11.8344 44.9491 11.5456 44.7362 11.3326C44.5232 11.1196 44.2343 11 43.9331 11Z" fill={v.ColorTeam} />
                                    <path d="M26.5468 19.7216L19.5399 11.4088C19.4344 11.2821 19.3025 11.1799 19.1535 11.1093C19.0044 11.0387 18.8418 11.0014 18.6768 11H12.1356C11.8344 11 11.5456 11.1196 11.3326 11.3326C11.1196 11.5456 11 11.8344 11 12.1356V18.6768C11.0014 18.8418 11.0387 19.0044 11.1093 19.1535C11.1799 19.3025 11.2821 19.4344 11.4088 19.5399L20.3576 27.0805L26.5468 19.7216Z" fill={v.ColorTeam} />
                                    <path d="M38.0621 33.2466L40.1971 31.1116C40.411 30.8978 40.5311 30.6077 40.5311 30.3053C40.5311 30.0029 40.411 29.7129 40.1971 29.499C39.9833 29.2852 39.6932 29.165 39.3908 29.165C39.0884 29.165 38.7984 29.2852 38.5845 29.499L36.5177 31.5772L35.382 30.2826L29.7039 35.0295L31.4755 36.5172L29.3973 38.584C29.2908 38.6896 29.2064 38.8152 29.1487 38.9536C29.0911 39.092 29.0614 39.2404 29.0614 39.3903C29.0614 39.5403 29.0911 39.6887 29.1487 39.8271C29.2064 39.9655 29.2908 40.0911 29.3973 40.1966C29.5029 40.3031 29.6285 40.3876 29.7668 40.4452C29.9052 40.5029 30.0537 40.5326 30.2036 40.5326C30.3535 40.5326 30.5019 40.5029 30.6403 40.4452C30.7787 40.3876 30.9043 40.3031 31.0099 40.1966L33.1449 38.0617L38.5618 43.49C39.2018 44.13 40.0699 44.4895 40.975 44.4895C41.8801 44.4895 42.7482 44.13 43.3882 43.49C44.0283 42.8499 44.3878 41.9819 44.3878 41.0767C44.3878 40.1716 44.0283 39.3036 43.3882 38.6635L38.0621 33.2466Z" fill={v.ColorTeam} />
                                    <defs>
                                      <linearGradient id="paint0_linear_943_2616" x1="28" y1="0" x2="28" y2="56" gradientUnits="userSpaceOnUse">
                                        <stop />
                                        <stop offset="1" stop-opacity="0.5" />
                                      </linearGradient>
                                    </defs>
                                  </svg>
                                </div>
                                <div className="box-top-start-event-sword-show-ui-box-top-side-scop-score-team">
                                  <p className='Score'>Điểm</p>
                                  <p className='ScoreTeam'>{v.ScoreTeam}</p>
                                </div>
                              </div>
                            </div>
                            <div className="box-top-start-event-sword-show-ui-box-bottom-side">
                              <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop">
                                {
                                  v.Buff > 1 ?
                                    <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff">
                                      <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff-icon">
                                        <p>{v.Buff == 2 ? 'x2' : 'x3'}</p>
                                      </div>
                                    </div>
                                    : v.Minus > 1 ?
                                      <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff">
                                        <div className="box-top-start-event-sword-show-ui-box-bottom-side-scop-buff-icon">
                                          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none">
                                              <path d="M22.1401 20.7005C21.2301 22.2105 20.0801 21.7305 19.0001 21.0905C17.9201 20.4505 16.9001 19.6805 16.2501 20.5905C15.5401 21.3705 16.0901 22.6205 16.3701 23.7205C16.6501 24.8305 16.6701 25.7905 14.9001 26.0005C13.5001 25.8105 13.5801 24.6505 13.8101 23.4205C14.0401 22.1905 14.4001 20.8905 13.5001 20.4305C12.7801 19.9505 12.2801 20.7805 11.6501 21.6005C11.0001 22.4105 10.2601 23.2005 9.04008 22.6205C7.94008 21.7105 8.36008 21.1805 8.94008 20.5005C9.52008 19.8205 10.2701 18.9105 9.84008 17.3105C9.66008 16.6605 8.76008 16.8105 7.87008 16.7905C7.00008 16.7705 6.12008 16.5905 6.03008 15.2905C5.96008 14.5005 6.55008 14.1805 7.16008 13.9305C7.78008 13.6805 8.41008 13.5005 8.42008 12.8705C8.45008 12.2605 8.04008 11.8305 7.78008 11.3805C7.52008 10.9305 7.41008 10.4605 8.03008 9.76046C9.08008 8.90046 9.92008 9.63046 10.7601 10.4205C11.6001 11.2105 12.4301 12.0405 13.4601 11.3905C14.2801 10.8505 13.5301 9.90046 12.9501 8.97046C12.3701 8.04046 11.9601 7.15046 13.4601 6.74046C14.7601 6.38046 15.2601 7.27046 15.7101 8.30046C16.1701 9.33046 16.5701 10.5005 17.6701 10.7105C19.2401 11.0005 20.3801 9.16046 21.4701 7.70046C22.5601 6.24046 23.6301 5.15046 25.0001 6.95046C26.5001 8.84046 25.0701 9.72046 23.4001 10.5005C21.7301 11.2305 19.8101 11.8705 20.2701 13.2805C20.5401 14.1005 21.4201 13.6505 22.3501 13.3405C23.2701 13.0305 24.2601 12.8605 24.7401 14.2705C25.2501 15.7605 24.0401 16.1005 22.6801 16.2405C21.3201 16.3805 19.8001 16.3205 19.7001 17.0005C19.5901 17.7105 20.5001 18.0005 21.2901 18.4205C22.0801 18.8505 22.7501 19.4205 22.1401 20.7005ZM24.5001 23.0005C23.5501 23.0005 23.0601 22.2605 23.0601 21.5005C23.0601 20.7405 23.5401 20.0005 24.5001 20.0005C25.5001 20.0005 26.0001 20.7405 26.0001 21.5005C26.0001 22.2605 25.5001 23.0005 24.5001 23.0005Z" fill="url(#paint1_linear_815_18563)" />
                                              <defs>
                                                <linearGradient id="paint0_linear_815_18563" x1="16" y1="0" x2="16" y2="32" gradientUnits="userSpaceOnUse">
                                                  <stop />
                                                  <stop offset="1" stop-opacity="0.5" />
                                                </linearGradient>
                                                <linearGradient id="paint1_linear_815_18563" x1="16.0122" y1="6.01172" x2="16.0122" y2="26.0005" gradientUnits="userSpaceOnUse">
                                                  <stop stop-color={DefaultColorStart} />
                                                  <stop offset="1" stop-color={DefaultColorStart} stop-opacity="0.25" />
                                                </linearGradient>
                                              </defs>
                                            </svg>
                                          </svg>
                                        </div>
                                      </div>
                                      : null
                                }

                              </div>
                            </div>
                          </div>
                        </>
                      )
                    }
                    return null;
                  })
                }
              </div>

            </div>
          :
          null
      }
      {
        OpenMenuSelectTeam ?
          <div className="box-body-select-team-event-sword">
            <div className="box-body-select-team-event-bg">
              <div className="box-body-select-team-header" style={{ background: SelectTeamColor ? SelectTeamColor : 'linear-gradient(90deg, rgba(0, 0, 0, 0.00) 0%, rgba(0, 0, 0, 0.75) 49.48%, rgba(0, 0, 0, 0.00) 100%)' }}>
                <p>{SelectTeamName ? 'You Are : ' + SelectTeamName : 'Select You Team'}</p>
              </div>
              <div className="box-body-select-detail-team">
                <div className="box-body-select-scop-team">
                  {
                    Object.values(DataTeam).map((v, i) => {
                      return (
                        <div className="box-body-select-team" key={v?.TeamName ?? i}>
                          <div className="box-body-select-team-bg" style={{ background: v.ColorBG }}>
                            <div className="box-body-select-team-scop">
                              <div className="box-header-select-team-detail">
                                <div className="box-header-select-team-left-side">
                                  <div className="box-header-select-team-icon-left-side">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36" fill="none">
                                      <rect width="36" height="36" rx="6" fill="url(#paint0_linear_912_419)" fill-opacity="0.5" />
                                      <rect x="0.5" y="0.5" width="35" height="35" rx="5.5" stroke={v.ColorTeam} stroke-opacity="0.5" />
                                      <path d="M27.3334 8H23.4934C23.3965 8.00083 23.3011 8.0231 23.2136 8.06526C23.1261 8.10742 23.0486 8.16846 22.9867 8.24413L13.02 20.2879L11.8067 19.0469C11.6811 18.9192 11.5109 18.8475 11.3333 18.8475C11.1558 18.8475 10.9855 18.9192 10.86 19.0469C10.7345 19.1746 10.6639 19.3478 10.6639 19.5284C10.6639 19.709 10.7345 19.8822 10.86 20.0099L12.1133 21.2848L8.92667 24.5195C8.74022 24.7085 8.59228 24.9331 8.49133 25.1804C8.39039 25.4277 8.33842 25.6928 8.33842 25.9606C8.33842 26.2283 8.39039 26.4935 8.49133 26.7408C8.59228 26.988 8.74022 27.2126 8.92667 27.4016C9.11248 27.5913 9.33326 27.7418 9.57637 27.8445C9.81947 27.9471 10.0801 28 10.3433 28C10.6066 28 10.8672 27.9471 11.1103 27.8445C11.3534 27.7418 11.5742 27.5913 11.76 27.4016L14.94 24.1601L16.1933 25.435C16.2553 25.4986 16.3291 25.549 16.4103 25.5835C16.4915 25.6179 16.5787 25.6356 16.6667 25.6356C16.7547 25.6356 16.8418 25.6179 16.9231 25.5835C17.0043 25.549 17.078 25.4986 17.14 25.435C17.2025 25.372 17.2521 25.297 17.2859 25.2143C17.3198 25.1317 17.3372 25.0431 17.3372 24.9535C17.3372 24.864 17.3198 24.7754 17.2859 24.6927C17.2521 24.6101 17.2025 24.5351 17.14 24.4721L15.92 23.2378L27.76 13.0996C27.8344 13.0366 27.8944 12.9578 27.9359 12.8688C27.9773 12.7798 27.9992 12.6827 28 12.5842V8.67814C28 8.49829 27.9298 8.3258 27.8048 8.19862C27.6797 8.07145 27.5102 8 27.3334 8Z" fill={v.ColorTeam} />
                                      <path d="M17.1267 13.2081L13.0133 8.24413C12.9514 8.16846 12.874 8.10742 12.7865 8.06526C12.699 8.0231 12.6035 8.00083 12.5067 8H8.66667C8.48986 8 8.32029 8.07145 8.19526 8.19862C8.07024 8.3258 8 8.49829 8 8.67814V12.5842C8.00081 12.6827 8.0227 12.7798 8.06415 12.8688C8.1056 12.9578 8.1656 13.0366 8.24 13.0996L13.4933 17.6025L17.1267 13.2081Z" fill={v.ColorTeam} />
                                      <path d="M23.8868 21.2847L25.1401 20.0098C25.2657 19.8821 25.3362 19.7089 25.3362 19.5283C25.3362 19.3477 25.2657 19.1745 25.1401 19.0468C25.0146 18.9192 24.8443 18.8474 24.6668 18.8474C24.4893 18.8474 24.319 18.9192 24.1935 19.0468L22.9801 20.2878L22.3134 19.5148L18.9801 22.3494L20.0201 23.2378L18.8001 24.472C18.7376 24.535 18.688 24.61 18.6542 24.6927C18.6203 24.7753 18.6029 24.8639 18.6029 24.9535C18.6029 25.043 18.6203 25.1316 18.6542 25.2143C18.688 25.2969 18.7376 25.3719 18.8001 25.4349C18.8621 25.4985 18.9358 25.549 19.0171 25.5834C19.0983 25.6178 19.1854 25.6355 19.2734 25.6355C19.3615 25.6355 19.4486 25.6178 19.5298 25.5834C19.6111 25.549 19.6848 25.4985 19.7468 25.4349L21.0001 24.16L24.1801 27.4016C24.5558 27.7837 25.0654 27.9985 25.5968 27.9985C26.1281 27.9985 26.6377 27.7837 27.0135 27.4016C27.3892 27.0194 27.6003 26.501 27.6003 25.9605C27.6003 25.42 27.3892 24.9016 27.0135 24.5195L23.8868 21.2847Z" fill={v.ColorTeam} />
                                      <defs>
                                        <linearGradient id="paint0_linear_912_419" x1="18" y1="0" x2="18" y2="36" gradientUnits="userSpaceOnUse">
                                          <stop />
                                          <stop offset="1" stop-opacity="0.5" />
                                        </linearGradient>
                                      </defs>
                                    </svg>
                                  </div>
                                  <div className="box-header-select-team-text">
                                    <p className='TeamName' style={{ color: v.ColorTeam }}>{v.TeamName}</p>
                                    <p className='SubNameTeam'>Chọn đội bạn muốn tham gia</p>
                                  </div>
                                </div>
                                <div className="box-header-select-team-right-side">
                                  <div className="box-header-select-team-icon-right-side">
                                    <p>{v.CountPeople}</p>
                                  </div>
                                </div>
                              </div>
                              <div className="box-body-select-team-detail" >
                                <div className="box-body-select-team-img-team" style={{ background: `url(${v.PicTeam})`, backgroundPosition: 'center', backgroundSize: 'cover', backgroundRepeat: 'no-repeat' }}>
                                  <div className="box-body-select-team-setting">
                                    <div className="box-body-select-team-text">
                                      <p>Nhấn ! tham gia với chúng tôi</p>
                                    </div>
                                    <div className="box-body-select-team-btn">
                                      <button style={{ backgroundColor: v.ColorTeam }} onClick={() => SelectTeam(i + 1, v.TeamName, v.ColorBGSelect, v.CountPeople, v.ColorSelect)} >Join Team</button>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      )
                    })
                  }
                </div>
              </div>
              <div className="box-body-select-footer">
                <p>Nhấn  <span>ESC</span>  để đóng</p>
              </div>
            </div>
          </div>
          : SelectTeamName !== null && SelectTeamColor !== null && DefaultColorTeam !== null ?
            <div className="box-top-mini-ui-select-team" style={{ background: DefaultColorTeam }}>
              <div className="box-top-mini-ui-scop">
                <div className="box-top-mini-ui-select-detail-my-team">
                  <div className="box-top-mini-ui-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36" fill="none">
                      <rect width="36" height="36" rx="6" fill="url(#paint0_linear_812_8558)" fill-opacity="0.5" />
                      <path d="M27.3334 8H23.4934C23.3966 8.00083 23.3011 8.0231 23.2136 8.06526C23.1261 8.10742 23.0487 8.16846 22.9867 8.24413L13.02 20.2879L11.8067 19.0469C11.6812 18.9192 11.5109 18.8475 11.3334 18.8475C11.1558 18.8475 10.9856 18.9192 10.86 19.0469C10.7345 19.1746 10.664 19.3478 10.664 19.5284C10.664 19.709 10.7345 19.8822 10.86 20.0099L12.1134 21.2848L8.92668 24.5195C8.74023 24.7085 8.59229 24.9331 8.49135 25.1804C8.3904 25.4277 8.33844 25.6928 8.33844 25.9606C8.33844 26.2283 8.3904 26.4935 8.49135 26.7408C8.59229 26.988 8.74023 27.2126 8.92668 27.4016C9.11249 27.5913 9.33328 27.7418 9.57638 27.8445C9.81949 27.9471 10.0801 28 10.3434 28C10.6066 28 10.8672 27.9471 11.1103 27.8445C11.3534 27.7418 11.5742 27.5913 11.76 27.4016L14.94 24.1601L16.1934 25.435C16.2553 25.4986 16.3291 25.549 16.4103 25.5835C16.4915 25.6179 16.5787 25.6356 16.6667 25.6356C16.7547 25.6356 16.8418 25.6179 16.9231 25.5835C17.0043 25.549 17.0781 25.4986 17.14 25.435C17.2025 25.372 17.2521 25.297 17.286 25.2143C17.3198 25.1317 17.3372 25.0431 17.3372 24.9535C17.3372 24.864 17.3198 24.7754 17.286 24.6927C17.2521 24.6101 17.2025 24.5351 17.14 24.4721L15.92 23.2378L27.76 13.0996C27.8344 13.0366 27.8944 12.9578 27.9359 12.8688C27.9773 12.7798 27.9992 12.6827 28 12.5842V8.67814C28 8.49829 27.9298 8.3258 27.8048 8.19862C27.6798 8.07145 27.5102 8 27.3334 8Z" fill={DefaultColorTeam} />
                      <path d="M17.1267 13.2081L13.0133 8.24413C12.9514 8.16846 12.874 8.10742 12.7865 8.06526C12.699 8.0231 12.6035 8.00083 12.5067 8H8.66667C8.48986 8 8.32029 8.07145 8.19526 8.19862C8.07024 8.3258 8 8.49829 8 8.67814V12.5842C8.00081 12.6827 8.0227 12.7798 8.06415 12.8688C8.1056 12.9578 8.1656 13.0366 8.24 13.0996L13.4933 17.6025L17.1267 13.2081Z" fill={DefaultColorTeam} />
                      <path d="M23.8868 21.285L25.1401 20.0101C25.2656 19.8824 25.3362 19.7092 25.3362 19.5286C25.3362 19.348 25.2656 19.1748 25.1401 19.0471C25.0146 18.9194 24.8443 18.8477 24.6668 18.8477C24.4892 18.8477 24.319 18.9194 24.1934 19.0471L22.9801 20.2881L22.3134 19.515L18.9801 22.3496L20.0201 23.238L18.8001 24.4722C18.7376 24.5353 18.688 24.6103 18.6542 24.6929C18.6203 24.7755 18.6029 24.8642 18.6029 24.9537C18.6029 25.0432 18.6203 25.1319 18.6542 25.2145C18.688 25.2971 18.7376 25.3721 18.8001 25.4352C18.8621 25.4987 18.9358 25.5492 19.0171 25.5836C19.0983 25.6181 19.1854 25.6358 19.2734 25.6358C19.3614 25.6358 19.4486 25.6181 19.5298 25.5836C19.6111 25.5492 19.6848 25.4987 19.7468 25.4352L21.0001 24.1603L24.1801 27.4018C24.5558 27.784 25.0654 27.9987 25.5968 27.9987C26.1281 27.9987 26.6377 27.784 27.0134 27.4018C27.3892 27.0196 27.6003 26.5012 27.6003 25.9607C27.6003 25.4202 27.3892 24.9019 27.0134 24.5197L23.8868 21.285Z" fill={DefaultColorTeam} />
                      <defs>
                        <linearGradient id="paint0_linear_812_8558" x1="18" y1="0" x2="18" y2="36" gradientUnits="userSpaceOnUse">
                          <stop />
                          <stop offset="1" stop-opacity="0.5" />
                        </linearGradient>
                      </defs>
                    </svg>
                  </div>
                  <div className="box-top-mini-ui-text">
                    <p className='TitleTeamName'>Đội của bạn</p>
                    <p className='SelectTeamName'>{SelectTeamName}</p>
                  </div>
                  <div className="box-top-mini-ui-count-people">
                    <p className='CountPeople'>{CountPeopleTeamSelect}</p>
                  </div>
                </div>
              </div>
            </div>
            : null
      }
      {
        OpenVictory ?
          <div className="box-victory-team-event-sword">
            <div className="box-victory-team-event-sword-text">
              <p>{TypeVictory}</p>
            </div>
            <div className="box-victory-team-event-color-victory" style={{ background: VictoryTeamColorBG }}>
              <div className="box-victory-team-event-box-all-text">
                <div className="box-victory-team-event-top-side">
                  <div className="box-victory-team-event-box-all">
                    <p>{TypeText}</p>
                  </div>
                  <div className="box-victory-box-icon-and-text-team">
                    <div className="box-icon-and-text-team">
                      <svg xmlns="http://www.w3.org/2000/svg" width="64" height="65" viewBox="0 0 64 65" fill="none">
                        <rect y="0.5" width="64" height="64" rx="8" fill="url(#paint0_linear_846_20617)" fill-opacity="0.5" />
                        <path d="M50.2092 13.0713H42.7336C42.5451 13.0729 42.3592 13.1155 42.1889 13.1962C42.0185 13.2769 41.8678 13.3937 41.7472 13.5385L22.3442 36.5885L19.9821 34.2134C19.7377 33.9691 19.4062 33.8318 19.0606 33.8318C18.715 33.8318 18.3835 33.9691 18.1391 34.2134C17.8947 34.4578 17.7574 34.7893 17.7574 35.1349C17.7574 35.4805 17.8947 35.812 18.1391 36.0564L20.5791 38.4964L14.3753 44.6872C14.0123 45.0489 13.7243 45.4787 13.5278 45.952C13.3313 46.4253 13.2301 46.9327 13.2301 47.4451C13.2301 47.9576 13.3313 48.465 13.5278 48.9383C13.7243 49.4115 14.0123 49.8414 14.3753 50.2031C14.737 50.5661 15.1669 50.8541 15.6401 51.0506C16.1134 51.2471 16.6208 51.3483 17.1333 51.3483C17.6457 51.3483 18.1531 51.2471 18.6264 51.0506C19.0997 50.8541 19.5295 50.5661 19.8912 50.2031L26.082 43.9993L28.522 46.4393C28.6426 46.5609 28.7862 46.6575 28.9443 46.7234C29.1025 46.7893 29.2721 46.8232 29.4435 46.8232C29.6148 46.8232 29.7844 46.7893 29.9426 46.7234C30.1008 46.6575 30.2443 46.5609 30.365 46.4393C30.4866 46.3186 30.5832 46.1751 30.649 46.0169C30.7149 45.8588 30.7489 45.6891 30.7489 45.5178C30.7489 45.3465 30.7149 45.1768 30.649 45.0187C30.5832 44.8605 30.4866 44.717 30.365 44.5963L27.9899 42.2342L51.0399 22.8312C51.1847 22.7106 51.3015 22.5599 51.3822 22.3895C51.4629 22.2192 51.5055 22.0333 51.5071 21.8448V14.3691C51.5071 14.0249 51.3704 13.6948 51.127 13.4514C50.8836 13.208 50.5535 13.0713 50.2092 13.0713Z" fill={VictoryTeamColor} />
                        <path d="M30.3396 23.0389L22.3318 13.5385C22.2111 13.3937 22.0604 13.2769 21.8901 13.1962C21.7197 13.1155 21.5339 13.0729 21.3454 13.0713H13.8697C13.5255 13.0713 13.1954 13.208 12.952 13.4514C12.7086 13.6948 12.5719 14.0249 12.5719 14.3691V21.8448C12.5734 22.0333 12.6161 22.2192 12.6967 22.3895C12.7774 22.5599 12.8943 22.7106 13.0391 22.8312L23.2662 31.449L30.3396 23.0389Z" fill={VictoryTeamColor} />
                        <path d="M43.4996 38.4967L45.9395 36.0567C46.1839 35.8123 46.3212 35.4808 46.3212 35.1352C46.3212 34.7896 46.1839 34.4581 45.9395 34.2137C45.6952 33.9693 45.3637 33.832 45.0181 33.832C44.6724 33.832 44.341 33.9693 44.0966 34.2137L41.7345 36.5888L40.4366 35.1092L33.9473 40.5343L35.972 42.2345L33.5969 44.5966C33.4752 44.7173 33.3787 44.8608 33.3128 45.019C33.2469 45.1771 33.213 45.3468 33.213 45.5181C33.213 45.6894 33.2469 45.8591 33.3128 46.0172C33.3787 46.1754 33.4752 46.3189 33.5969 46.4396C33.7175 46.5612 33.8611 46.6578 34.0192 46.7237C34.1774 46.7896 34.347 46.8235 34.5184 46.8235C34.6897 46.8235 34.8593 46.7896 35.0175 46.7237C35.1757 46.6578 35.3192 46.5612 35.4399 46.4396L37.8798 43.9996L44.0706 50.2034C44.8021 50.9348 45.7941 51.3458 46.8286 51.3458C47.863 51.3458 48.8551 50.9348 49.5865 50.2034C50.318 49.4719 50.7289 48.4798 50.7289 47.4454C50.7289 46.411 50.318 45.4189 49.5865 44.6875L43.4996 38.4967Z" fill={VictoryTeamColor} />
                        <defs>
                          <linearGradient id="paint0_linear_846_20617" x1="32" y1="0.5" x2="32" y2="64.5" gradientUnits="userSpaceOnUse">
                            <stop />
                            <stop offset="1" stop-opacity="0.5" />
                          </linearGradient>
                        </defs>
                      </svg>
                    </div>
                    <div className="box-victory-name-team-win">
                      <p style={{ color: VictoryTeamColor }}>{VictoryTeam}</p>
                    </div>
                    <div className="box-icon-and-text-team">
                      <svg xmlns="http://www.w3.org/2000/svg" width="64" height="65" viewBox="0 0 64 65" fill="none">
                        <rect y="0.5" width="64" height="64" rx="8" fill="url(#paint0_linear_846_20617)" fill-opacity="0.5" />
                        <path d="M50.2092 13.0713H42.7336C42.5451 13.0729 42.3592 13.1155 42.1889 13.1962C42.0185 13.2769 41.8678 13.3937 41.7472 13.5385L22.3442 36.5885L19.9821 34.2134C19.7377 33.9691 19.4062 33.8318 19.0606 33.8318C18.715 33.8318 18.3835 33.9691 18.1391 34.2134C17.8947 34.4578 17.7574 34.7893 17.7574 35.1349C17.7574 35.4805 17.8947 35.812 18.1391 36.0564L20.5791 38.4964L14.3753 44.6872C14.0123 45.0489 13.7243 45.4787 13.5278 45.952C13.3313 46.4253 13.2301 46.9327 13.2301 47.4451C13.2301 47.9576 13.3313 48.465 13.5278 48.9383C13.7243 49.4115 14.0123 49.8414 14.3753 50.2031C14.737 50.5661 15.1669 50.8541 15.6401 51.0506C16.1134 51.2471 16.6208 51.3483 17.1333 51.3483C17.6457 51.3483 18.1531 51.2471 18.6264 51.0506C19.0997 50.8541 19.5295 50.5661 19.8912 50.2031L26.082 43.9993L28.522 46.4393C28.6426 46.5609 28.7862 46.6575 28.9443 46.7234C29.1025 46.7893 29.2721 46.8232 29.4435 46.8232C29.6148 46.8232 29.7844 46.7893 29.9426 46.7234C30.1008 46.6575 30.2443 46.5609 30.365 46.4393C30.4866 46.3186 30.5832 46.1751 30.649 46.0169C30.7149 45.8588 30.7489 45.6891 30.7489 45.5178C30.7489 45.3465 30.7149 45.1768 30.649 45.0187C30.5832 44.8605 30.4866 44.717 30.365 44.5963L27.9899 42.2342L51.0399 22.8312C51.1847 22.7106 51.3015 22.5599 51.3822 22.3895C51.4629 22.2192 51.5055 22.0333 51.5071 21.8448V14.3691C51.5071 14.0249 51.3704 13.6948 51.127 13.4514C50.8836 13.208 50.5535 13.0713 50.2092 13.0713Z" fill={VictoryTeamColor} />
                        <path d="M30.3396 23.0389L22.3318 13.5385C22.2111 13.3937 22.0604 13.2769 21.8901 13.1962C21.7197 13.1155 21.5339 13.0729 21.3454 13.0713H13.8697C13.5255 13.0713 13.1954 13.208 12.952 13.4514C12.7086 13.6948 12.5719 14.0249 12.5719 14.3691V21.8448C12.5734 22.0333 12.6161 22.2192 12.6967 22.3895C12.7774 22.5599 12.8943 22.7106 13.0391 22.8312L23.2662 31.449L30.3396 23.0389Z" fill={VictoryTeamColor} />
                        <path d="M43.4996 38.4967L45.9395 36.0567C46.1839 35.8123 46.3212 35.4808 46.3212 35.1352C46.3212 34.7896 46.1839 34.4581 45.9395 34.2137C45.6952 33.9693 45.3637 33.832 45.0181 33.832C44.6724 33.832 44.341 33.9693 44.0966 34.2137L41.7345 36.5888L40.4366 35.1092L33.9473 40.5343L35.972 42.2345L33.5969 44.5966C33.4752 44.7173 33.3787 44.8608 33.3128 45.019C33.2469 45.1771 33.213 45.3468 33.213 45.5181C33.213 45.6894 33.2469 45.8591 33.3128 46.0172C33.3787 46.1754 33.4752 46.3189 33.5969 46.4396C33.7175 46.5612 33.8611 46.6578 34.0192 46.7237C34.1774 46.7896 34.347 46.8235 34.5184 46.8235C34.6897 46.8235 34.8593 46.7896 35.0175 46.7237C35.1757 46.6578 35.3192 46.5612 35.4399 46.4396L37.8798 43.9996L44.0706 50.2034C44.8021 50.9348 45.7941 51.3458 46.8286 51.3458C47.863 51.3458 48.8551 50.9348 49.5865 50.2034C50.318 49.4719 50.7289 48.4798 50.7289 47.4454C50.7289 46.411 50.318 45.4189 49.5865 44.6875L43.4996 38.4967Z" fill={VictoryTeamColor} />
                        <defs>
                          <linearGradient id="paint0_linear_846_20617" x1="32" y1="0.5" x2="32" y2="64.5" gradientUnits="userSpaceOnUse">
                            <stop />
                            <stop offset="1" stop-opacity="0.5" />
                          </linearGradient>
                        </defs>
                      </svg>
                    </div>
                  </div>
                  <div className="box-victory-team-score-team">
                    <p>Điểm đội bạn : <span>{VictoryTeamScore}</span></p>
                  </div>
                </div>
                <div className="box-victory-team-event-bottom-side">
                  {
                    Object.values(VictoryItemReward).map((v, i) => {
                      return (
                        <div className="box-victory-team-event-item-reward" key={v?.name ?? i}>
                          <div className="box-victory-team-event-item-reward-img" >
                            <img src={getItemImageUrl(v.name, 'png')} onError={onItemImgError} alt="" />
                          </div>
                        </div>
                      )
                    })
                  }
                </div>
              </div>
            </div>
          </div>
          : null
      }
      {
        OpenMenuAdmin ?
          <div className="box-menu-admin-event-sword">
            <div className="box-menu-admin-event-sword-scop">
              <div className="box-menu-admin-event-sword-header">
                <div className="box-menu-admin-event-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40" fill="none">
                    <rect width="40" height="40" rx="8" fill="white" fill-opacity="0.1" />
                    <path d="M11 10.4932V11.9984H9.59376C9.26999 12.0131 8.94979 11.9257 8.67815 11.7486C8.40651 11.5715 8.1971 11.3135 8.07935 11.011C8.00152 10.7758 7.98056 10.5254 8.01817 10.2805C8.05578 10.0355 8.1509 9.80306 8.29569 9.60214C8.48426 9.35021 8.74695 9.16388 9.04678 9.06938C9.3466 8.97488 9.66846 8.97696 9.96704 9.07535C10.2656 9.17373 10.5259 9.36345 10.7112 9.61781C10.8965 9.87216 10.9975 10.1783 11 10.4932Z" fill="white" fill-opacity="0.25" />
                    <path d="M20.0435 17.2567C20.9223 17.2567 21.6348 16.5458 21.6348 15.6689C21.6348 14.792 20.9223 14.0811 20.0435 14.0811C19.1646 14.0811 18.4522 14.792 18.4522 15.6689C18.4522 16.5458 19.1646 17.2567 20.0435 17.2567Z" fill="white" fill-opacity="0.25" />
                    <path d="M26.4375 9H12C12.2471 9.46019 12.3757 9.96971 12.375 10.4865V29.5135C12.375 29.9078 12.5396 30.2858 12.8326 30.5646C13.1257 30.8434 13.5231 31 13.9375 31H26.4375C26.8519 31 27.2493 30.8434 27.5424 30.5646C27.8354 30.2858 28 29.9078 28 29.5135V10.4865C28 10.0922 27.8354 9.71415 27.5424 9.43538C27.2493 9.15661 26.8519 9 26.4375 9ZM20.1875 11.973C20.8674 11.973 21.532 12.1648 22.0973 12.5241C22.6626 12.8835 23.1032 13.3942 23.3633 13.9918C23.6235 14.5893 23.6916 15.2469 23.5589 15.8812C23.4263 16.5156 23.0989 17.0983 22.6182 17.5557C22.1374 18.013 21.5249 18.3245 20.8581 18.4507C20.1913 18.5769 19.5001 18.5121 18.872 18.2646C18.2439 18.0171 17.707 17.5979 17.3293 17.0601C16.9516 16.5223 16.75 15.89 16.75 15.2432C16.75 14.3759 17.1122 13.5441 17.7568 12.9308C18.4015 12.3175 19.2758 11.973 20.1875 11.973ZM23.9375 28.027H16.4375C16.1889 28.027 15.9504 27.9331 15.7746 27.7658C15.5988 27.5985 15.5 27.3717 15.5 27.1351C15.5 26.8986 15.5988 26.6717 15.7746 26.5045C15.9504 26.3372 16.1889 26.2432 16.4375 26.2432H23.9375C24.1861 26.2432 24.4246 26.3372 24.6004 26.5045C24.7762 26.6717 24.875 26.8986 24.875 27.1351C24.875 27.3717 24.7762 27.5985 24.6004 27.7658C24.4246 27.9331 24.1861 28.027 23.9375 28.027ZM23.9375 23.2703H16.4375C16.1889 23.2703 15.9504 23.1763 15.7746 23.009C15.5988 22.8418 15.5 22.6149 15.5 22.3784C15.5 22.1418 15.5988 21.915 15.7746 21.7477C15.9504 21.5805 16.1889 21.4865 16.4375 21.4865H23.9375C24.1861 21.4865 24.4246 21.5805 24.6004 21.7477C24.7762 21.915 24.875 22.1418 24.875 22.3784C24.875 22.6149 24.7762 22.8418 24.6004 23.009C24.4246 23.1763 24.1861 23.2703 23.9375 23.2703Z" fill="white" fill-opacity="0.25" />
                  </svg>
                </div>
                <div className="box-menu-admin-event-text-header">
                  <p className='TextHeader'>Bảng quản trị Admin</p>
                  <p className='SubTextHeader'> Được setting bởi Team UL </p>
                </div>
              </div>
              <div className="box-menu-admin-event-time-zone">
                <p>{daysOfWeek[GetDay]}, {DateAndTime}</p>
              </div>
              <div className="box-menu-admin-body-event-sword">
                <div className="box-menu-admin-body-event-sword-left-side">
                  <div className={"box-menu-admin-body-tag-general" + (RewardsMenu ? ' disabled' : ' active')}>
                    <p>Chung</p>
                  </div>
                  <div className={"box-menu-admin-body-tag-rewards" + (RewardsMenu ? ' active' : ' disabled')}>
                    <p>Nhận thưởng</p>
                  </div>
                </div>
                <div className="box-menu-admin-body-event-sword-right-side">
                  <div className="box-menu-admin-body-event-sword-right-padding">
                    <div className="box-menu-admin-body-event-sword-right-top-header">
                      <p className='admin-text-header'>Cài đặt chung</p>
                      <p className='admin-sub-text-header'>Các cài đặt cơ bản cho hoạt động War Team có thể được điều chỉnh hoặc thiết lập bất kỳ lúc nào theo quyết định của Admin.</p>
                      {
                        !RewardsMenu ?
                          <div className="box-menu-admin-setting-menu">
                            <div className="box-menu-admin-setting-menu-top-side">
                              <p>Các hình thức người chơi tham gia vào hoạt động</p>
                              <div className="box-menu-admin-setting-menu-top-side-input-select">
                                <div className="box-menu-admin-setting-menu-top-side-input-select-scop">
                                  <input type="radio" name="selectradio" id="1" onChange={() => setTypeGamePlay(1)} />Select Team
                                </div>
                                <div className="box-menu-admin-setting-menu-top-side-input-select-scop">
                                  <input type="radio" name="selectradio" id="2" onChange={() => setTypeGamePlay(2)} /> Random Team
                                </div>
                              </div>
                            </div>
                            <div className="box-menu-admin-setting-menu-bottom-side">
                              <div className="box-menu-admin-setting-menu-bottom-side-right-side">
                                <p>Time :</p>
                                <div className="box-menu-admin-setting-menu-bottom-side-right-side-input">
                                  <div className="box-menu-admin-minute">
                                    <input type="number" placeholder='00' value={InputTimeEvent} onChange={(e) => CheckHourAndMinute(e.target.value, 'timeevent')} />
                                  </div>
                                  <div className="box-menu-admin-hour-center-minute">
                                    <p>phút.</p>
                                  </div>
                                </div>
                              </div>
                              <div className="box-menu-admin-setting-menu-bottom-side-right-side">
                                <p>Chọn số lượng đội (Chỉ số cuối cùng trong Config.TeamData chính là số đội tối đa) :</p>
                                <div className="box-menu-admin-setting-menu-bottom-side-right-side-input">
                                  <div className="box-menu-admin-minute">
                                    <input type="number" placeholder='00' value={CountTeamToPlayer} onChange={(e) => CheckHourAndMinute(e.target.value, 'count')} />
                                  </div>
                                  <div className="box-menu-admin-hour-center-minute">
                                    <p>Đội</p>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                          :
                          !OpenMenuDataItemRewards && !OpenMenuDataItem ?
                            <div className="box-menu-admin-setting-menu">
                              <div className="box-menu-admin-setting-menu-top-side">
                                <p>Phần thưởng của đội thắng cuộc :</p>
                                <div className="box-menu-admin-setting-menu-top-side-reward-select-select-two">
                                  {
                                    Object.values(DataItemSelectRewards).map((v, i) => {
                                      return (
                                        <div className="box-menu-admin-setting-menu-top-side-reward-select-box" key={v?.name ?? i} >
                                          <div className="box-menu-admin-setting-menu-top-side-reward-select-box-img" onClick={() => DeleteItemSelect(v)}>
                                            <img src={getItemImageUrl(v.name, 'png')} onError={onItemImgError} alt="" />
                                          </div>
                                          <div className="box-menu-admin-setting-menu-top-side-reward-select-box-input-count">
                                            <input type="number" placeholder='0' value={v.count} onChange={(e) => AddCountItemRewards(e.target.value, v)} />
                                          </div>
                                        </div>
                                      )
                                    })
                                  }
                                  <div className="box-menu-admin-setting-menu-top-side-reward-select-box">
                                    <div className="box-menu-admin-setting-menu-top-side-reward-select-box-img" onClick={() => setOpenMenuDataItemRewards(true)}>
                                      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
                                        <path d="M10 0C8.89543 0 8 0.895432 8 2V8H2C0.89543 8 0 8.89543 0 10C0 11.1046 0.895432 12 2 12H8V18C8 19.1046 8.89543 20 10 20C11.1046 20 12 19.1046 12 18V12H18C19.1046 12 20 11.1046 20 10C20 8.89543 19.1046 8 18 8H12V2C12 0.89543 11.1046 0 10 0Z" fill="#D9D9D9" fill-opacity="0.15" />
                                      </svg>
                                    </div>
                                  </div>
                                </div>
                              </div>
                              <div className="box-menu-admin-setting-menu-bottom-side-reward">
                                <p>Phần thưởng cho người tham gia (Đội thua) :</p>
                                <div className="box-menu-admin-setting-menu-top-side-reward-select-select-two">
                                  {
                                    Object.values(DataItemSelect).map((v, i) => {
                                      return (
                                        <div className="box-menu-admin-setting-menu-top-side-reward-select-box" key={v?.name ?? i} >
                                          <div className="box-menu-admin-setting-menu-top-side-reward-select-box-img" onClick={() => DeleteItem(v)}>
                                            <img src={getItemImageUrl(v.name, 'png')} onError={onItemImgError} alt="" />
                                          </div>
                                          <div className="box-menu-admin-setting-menu-top-side-reward-select-box-input-count">
                                            <input type="number" placeholder='0' value={v.count} onChange={(e) => AddCountItem(e.target.value, v)} />
                                          </div>
                                        </div>
                                      )
                                    })
                                  }
                                  <div className="box-menu-admin-setting-menu-top-side-reward-select-box">
                                    <div className="box-menu-admin-setting-menu-top-side-reward-select-box-img" onClick={() => setOpenMenuDataItem(true)}>
                                      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
                                        <path d="M10 0C8.89543 0 8 0.895432 8 2V8H2C0.89543 8 0 8.89543 0 10C0 11.1046 0.895432 12 2 12H8V18C8 19.1046 8.89543 20 10 20C11.1046 20 12 19.1046 12 18V12H18C19.1046 12 20 11.1046 20 10C20 8.89543 19.1046 8 18 8H12V2C12 0.89543 11.1046 0 10 0Z" fill="#D9D9D9" fill-opacity="0.15" />
                                      </svg>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                            :
                            <div className="box-menu-admin-setting-menu">
                              <div className="box-menu-admin-setting-menu-top-side">
                                <p>All Item In System :</p>
                                <div className="box-menu-admin-setting-menu-top-side-reward-select-select">
                                  {
                                    OpenMenuDataItemRewards ?
                                      Object.values(DataItemHudRewards).filter((v) => v.name.toLowerCase().includes(searchText.toLowerCase())).map((v, i) => {
                                        return (
                                          <div className="box-menu-admin-setting-menu-top-side-reward-select-box" key={v?.name ?? i} onClick={() => AddItemRewards(v)}>
                                            <div className="box-menu-admin-setting-menu-top-side-reward-select-box-img">
                                              <img src={getItemImageUrl(v.name, 'png')} onError={onItemImgError} alt="" />
                                            </div>
                                          </div>
                                        )
                                      })
                                      :
                                      Object.values(DataItemHud).filter((v) => v.name.toLowerCase().includes(searchText.toLowerCase())).map((v, i) => {
                                        return (
                                          <div className="box-menu-admin-setting-menu-top-side-reward-select-box" key={v?.name ?? i} onClick={() => AddItem(v)}>
                                            <div className="box-menu-admin-setting-menu-top-side-reward-select-box-img">
                                              <img src={getItemImageUrl(v.name, 'png')} onError={onItemImgError} alt="" />
                                            </div>
                                          </div>
                                        )
                                      })
                                  }
                                </div>
                              </div>
                            </div>


                      }

                    </div>
                  </div>
                </div>
              </div>
              <div className="box-menu-admin-bottom-event-sword">
                {
                  OpenMenuDataItemRewards ?
                    <>
                      <button onClick={() => setOpenMenuDataItemRewards(false)}>Trở về</button>
                      <input type="text"
                        placeholder="Search"
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)} />
                    </>
                    : OpenMenuDataItem ?
                      <>
                        <button onClick={() => setOpenMenuDataItem(false)}>Trở về</button>
                        <input type="text"
                          placeholder="Search"
                          value={searchText}
                          onChange={(e) => setSearchText(e.target.value)} />
                      </>
                      : RewardsMenu ?
                        <>
                          <button onClick={() => CharGerPage()}>Trở về</button>
                          <button onClick={() => StarGame()}>Bắt đầu</button>
                        </>
                        : <button onClick={() => CharGerPage()}>Tiếp </button>
                }
              </div>
            </div>
          </div>

          : null
      }
    </div>
  )
}

export default App
