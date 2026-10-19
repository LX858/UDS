import { Box, Text } from 'lr-components'
import React from 'react'
import { useSelector } from 'react-redux'
import { RootState } from '../store'
import MenuPageShell from '../components/MenuPageShell'

function Settings() {
	const store = useSelector((state: RootState) => state.main)

	return (
		<MenuPageShell active={store.page === 'settings'}>
			<Box width={'100%'} height={'100%'} display='flex' alignItems='center' justifyContent='center'>
				<Text rFontSize={50} color='#FFFFFF50'>
					ĐANG CẬP NHẬT
				</Text>
			</Box>
		</MenuPageShell>
	)
}

export default Settings
