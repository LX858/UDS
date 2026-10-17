import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

export type ModalType =
	| 'create-grade'
	| 'edit-grade-label'
	| 'edit-grade-permissions'
	| 'delete-grade'
	| 'edit-member'
	| 'kick-member'
	| 'edit-info'
	| 'edit-slogan'
	| 'fund-contribution'
	| 'self-action-warning'
	| 'permission-denied'
	| 'leave-faction'
	| 'transfer-gang-owner'
	| 'disband-gang'
	| null

interface ModalState {
	open: ModalType | null
	setOpen: (open: ModalType | null) => void
	title?: string
	payload?: any
	openModal: (type: ModalType, title?: string, payload?: any) => void
	closeModal: () => void
}

export const useModalStore = create<ModalState>()(
	devtools(
		(set) => ({
			open: null,
			title: '',
			payload: undefined,
			setOpen: (open) => set({ open }),
			openModal: (type, title, payload) => set({ open: type, title, payload }),
			closeModal: () => set({ open: null, title: '', payload: undefined })
		}),
		{ name: 'ModalStore' }
	)
)
