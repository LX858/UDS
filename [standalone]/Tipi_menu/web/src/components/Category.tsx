import { Box } from 'lr-components'
import React from 'react'
import { AppDispatch, RootState } from '../store'
import { useDispatch, useSelector } from 'react-redux'
import { setPage } from '../store/main'
import { fetchNui } from '../utils/fetchNui'
import { useLocale } from '../hooks/useLocale'
import NavTab from './NavTab'
const onButtonAction = (key: string, value?: string) => {
	fetchNui('main:action', { key, value })
}

function Category() {
	const L = useLocale()
	const store = useSelector((state: RootState) => state.main)
	const dispatch = useDispatch<AppDispatch>()
	const onCategory = (key: string) => {
		if (key === 'shop') {
			fetchNui('getPrimeTicket')
		}
		dispatch(setPage(key))
	}
	return (
		<Box
			rWidth={1728}
			rHeight={72}
			rTop={120}
			left={'50%'}
			transform='translateX(-50%)'
			position='absolute'
			zIndex={30}
			display='flex'
			alignItems='stretch'
			justifyContent='stretch'
			rGap={8}>
			<NavTab
				active={store.page === 'main'}
				label={L('ui.nav.info')}
				onClick={() => onCategory('main')}
				icon={
					<Box
						rWidth={26}
						rHeight={24}
						backgroundImage='url(./assets/svg/info.svg)'
						backgroundPosition='center'
						backgroundRepeat='no-repeat'
						backgroundSize='cover'
						flexShrink={0}
					/>
				}
			/>
			<NavTab
				active={store.page === 'shop'}
				label={L('ui.nav.shop')}
				onClick={() => onCategory('shop')}
				icon={
					<Box
						rWidth={24}
						rHeight={24}
						backgroundImage='url(./assets/svg/event.svg)'
						backgroundPosition='center'
						backgroundRepeat='no-repeat'
						backgroundSize='cover'
						flexShrink={0}
					/>
				}
			/>
			<NavTab
				active={store.page === 'business'}
				label={L('ui.nav.business')}
				onClick={() => onCategory('business')}
				icon={
					<Box
						rWidth={26}
						rHeight={24}
						backgroundImage='url(./assets/svg/leaderboard.svg)'
						backgroundPosition='center'
						backgroundRepeat='no-repeat'
						backgroundSize='contain'
						flexShrink={0}
					/>
				}
			/>
			<NavTab
				active={store.page === 'settings'}
				label={L('ui.nav.settings')}
				onClick={() => onButtonAction('openSetting')}
				icon={
					<Box
						rWidth={28}
						rHeight={24}
						backgroundImage='url(./assets/svg/setting.svg)'
						backgroundPosition='center'
						backgroundRepeat='no-repeat'
						backgroundSize='cover'
						flexShrink={0}
					/>
				}
			/>
		</Box>
	)
}

export default Category
