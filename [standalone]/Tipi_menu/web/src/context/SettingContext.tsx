import { createContext } from 'react'
import { DefaultUISetting, ISettingContext } from '../types'

export const SettingContext = createContext<ISettingContext>(DefaultUISetting)
