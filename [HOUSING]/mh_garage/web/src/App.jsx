import { useState, useEffect } from 'react'
import Garage from './components/Garage'

// Polyfill for development
if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = () => 'mh_garage'
}

function App() {
  const [visible, setVisible] = useState(false)
  const [garageData, setGarageData] = useState(null)

  useEffect(() => {
    const handleMessage = (event) => {
      const data = event.data

      if (data.action === 'openGarage') {
        console.log('[MH_GARAGE NUI] Received openGarage:', data.garageData)
        console.log('[MH_GARAGE NUI] Vehicles count:', data.garageData?.vehicles?.length || 0)
        setGarageData(data.garageData)
        setVisible(true)
      }

      if (data.action === 'closeGarage') {
        setVisible(false)
        setGarageData(null)
      }

      if (data.action === 'updateVehicles') {
        console.log('[MH_GARAGE NUI] Received updateVehicles:', data.vehicles)
        setGarageData(prev => ({
          ...prev,
          vehicles: data.vehicles
        }))
      }
    }

    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  const closeUI = () => {
    setVisible(false)
    setGarageData(null)
    fetch(`https://${GetParentResourceName()}/closeNUI`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    })
  }

  if (!visible || !garageData) return null

  return <Garage garageData={garageData} onClose={closeUI} />
}

export default App
