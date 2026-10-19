import React, { Suspense } from 'react'
import { Box } from 'lr-components'
import { RootState } from '../store'
import { useSelector } from 'react-redux'
import MenuPageShell from '../components/MenuPageShell'

const LeaderboardEmbed = React.lazy(() => import('./LeaderboardEmbed'))

function Business() {
	const store = useSelector((state: RootState) => state.main)

	return (
		<MenuPageShell active={store.page === 'business'} showPanelChrome={false} className='mp-lb-page'>
			{store.page === 'business' && (
				<Box
					width='100%'
					height='100%'
					minHeight={0}
					position='relative'
					backgroundColor='var(--bg-card)'
					border='1px solid var(--border-dim)'
					rBorderRadius={4}
					boxSizing='border-box'
					className='mp-lb-page-inner'>
					<Suspense
						fallback={
							<Box
								width='100%'
								height='100%'
								display='flex'
								alignItems='center'
								justifyContent='center'
								className='mp-lb-embed'>
								<span className='text-sm text-white/40'>Đang tải bảng xếp hạng...</span>
							</Box>
						}>
						<LeaderboardEmbed />
					</Suspense>
				</Box>
			)}
		</MenuPageShell>
	)
}

export default Business
