import { useState, useCallback } from 'react'
import './Garage.css'

// Polyfill for development
if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = () => 'mh_garage'
}

const VehicleCard = ({ vehicle, isSelected, onClick, onTakeout }) => {
  // Use vehicle.vehicle (spawn name) for image, fallback to model
  const vehicleSpawn = vehicle.vehicle || vehicle.model
  const vehicleImageUrl = `https://raw.githubusercontent.com/xuannguyen995/vehicle_mini/main/${vehicleSpawn}.webp`
  
  const getClassLabel = (classId) => {
    const classes = {
      0: 'Compacts', 1: 'Sedans', 2: 'SUVs', 3: 'Coupes', 4: 'Muscle',
      5: 'Sports Classics', 6: 'Sports', 7: 'Super', 8: 'Motorcycles',
      9: 'Off-road', 10: 'Industrial', 11: 'Utility', 12: 'Vans',
      13: 'Cycles', 14: 'Boats', 15: 'Helicopters', 16: 'Planes',
      17: 'Service', 18: 'Emergency', 19: 'Military', 20: 'Commercial', 21: 'Trains'
    }
    return classes[classId] || 'Unknown'
  }

  const getFuelColor = (fuel) => {
    if (fuel < 25) return '#ff3366'
    if (fuel < 50) return '#ffcc00'
    return '#00ff88'
  }

  const getHealthColor = (health) => {
    if (health < 30) return '#ff3366'
    if (health < 60) return '#ffcc00'
    return '#00F8B9'
  }

  return (
    <div 
      className={`vehicle-card ${isSelected ? 'selected' : ''}`}
      onClick={onClick}
    >
      <div className="vehicle-image-container">
        <div className="vehicle-class-badge">{getClassLabel(vehicle.class)}</div>
        <div className="vehicle-plate-container">
          <img src="./plate.png" alt="plate" className="plate-bg" />
          <span className="plate-text">{vehicle.plate}</span>
        </div>
        <img 
          src={vehicleImageUrl} 
          alt={vehicle.name || vehicle.model}
          className="vehicle-img"
          onError={(e) => {
            e.target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 120"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:%23141428"/><stop offset="100%" style="stop-color:%230a0a12"/></linearGradient></defs><rect fill="url(%23g)" width="200" height="120"/><text fill="%2300f0ff" font-family="Arial" font-size="12" x="50%" y="50%" text-anchor="middle" dy=".3em" opacity="0.5">NO IMAGE</text></svg>'
          }}
        />
      </div>
      {/* Vehicle Stats Bars - Below Image */}
      <div className="vehicle-stats">
        <div className="stat-item">
          <div className="stat-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke={getFuelColor(vehicle.fuel || 0)} strokeWidth="2">
              <path d="M3 22h12M4 9h10a1 1 0 011 1v11H3V10a1 1 0 011-1zM8 9V5a2 2 0 012-2h2a2 2 0 012 2v4"/>
            </svg>
          </div>
          <div className="stat-bar-wrapper">
            <div className="stat-bar" style={{ width: `${vehicle.fuel || 0}%`, backgroundColor: getFuelColor(vehicle.fuel || 0) }}></div>
          </div>
        </div>
        <div className="stat-item">
          <div className="stat-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke={getHealthColor(vehicle.body || 100)} strokeWidth="2">
              <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 002 12v4c0 .6.4 1 1 1h2"/>
              <circle cx="7" cy="17" r="2"/>
              <circle cx="17" cy="17" r="2"/>
            </svg>
          </div>
          <div className="stat-bar-wrapper">
            <div className="stat-bar" style={{ width: `${vehicle.body || 100}%`, backgroundColor: getHealthColor(vehicle.body || 100) }}></div>
          </div>
        </div>
        <div className="stat-item">
          <div className="stat-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke={getHealthColor(vehicle.engine || 100)} strokeWidth="2">
              <circle cx="12" cy="12" r="3"/>
              <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/>
            </svg>
          </div>
          <div className="stat-bar-wrapper">
            <div className="stat-bar" style={{ width: `${vehicle.engine || 100}%`, backgroundColor: getHealthColor(vehicle.engine || 100) }}></div>
          </div>
        </div>
      </div>
      <div className="vehicle-info">
        <h3 className="vehicle-name">{vehicle.name || vehicle.model}</h3>
      </div>
      <div className="vehicle-actions">
        <button className="btn-takeout" onClick={(e) => { e.stopPropagation(); onTakeout(vehicle); }}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M5 12h14M12 5l7 7-7 7"/>
          </svg>
          Lấy Xe
        </button>
      </div>
    </div>
  )
}

const Garage = ({ garageData, onClose }) => {
  const [selectedVehicle, setSelectedVehicle] = useState(null)
  const [currentFloor, setCurrentFloor] = useState(1)
  const [isLoading, setIsLoading] = useState(false)

  const { garageName, vehicles = [], doesOwn, price, garageInfo, interior, totalFloors = 1, pricetakeout = 0 } = garageData

  const fetchNUI = useCallback((event, data = {}) => {
    return fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }).then(resp => resp.json()).catch(() => ({}))
  }, [])

  const handleEnterGarage = async () => {
    if (!doesOwn) return
    setIsLoading(true)
    await fetchNUI('enterGarage', { garageName, floor: currentFloor })
    setIsLoading(false)
  }

  const handleBuyGarage = async () => {
    setIsLoading(true)
    await fetchNUI('buyGarage', { garageName, interior })
    setIsLoading(false)
  }

  const handlePreviewGarage = async () => {
    setIsLoading(true)
    await fetchNUI('previewGarage', { garageName, interior })
    setIsLoading(false)
  }

  const handleRefreshGarage = async () => {
    setIsLoading(true)
    await fetchNUI('refreshGarage', { garageName })
    setIsLoading(false)
  }

  const handleTakeoutVehicle = async (vehicle) => {
    setIsLoading(true)
    await fetchNUI('takeoutVehicle', { garageName, plate: vehicle.plate, vehicle })
    setIsLoading(false)
  }

  const handleFloorChange = async (floor) => {
    setCurrentFloor(floor)
    setSelectedVehicle(null)
    setIsLoading(true)
    await fetchNUI('changeFloor', { garageName, floor })
    setIsLoading(false)
  }

  const formatNumber = (num) => {
    return num?.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") || "0"
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      onClose()
    }
  }

  return (
    <div className="garage-container" onKeyDown={handleKeyDown} tabIndex={0}>
      <div className="garage-panel">
        {/* Corner decorations */}
        <div className="corner-decoration top-left"></div>
        <div className="corner-decoration top-right"></div>
        <div className="corner-decoration bottom-left"></div>
        <div className="corner-decoration bottom-right"></div>

        {/* Header */}
        <div className="garage-header">
          <div className="header-left">
            <div className="header-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
              </svg>
            </div>
            <div className="header-text">
              <h1 className="garage-title">{garageName}</h1>
              <p className="garage-subtitle">{garageInfo || 'Private Garage System'}</p>
            </div>
          </div>
          <button className="btn-close" onClick={onClose}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        {/* Main Content */}
        <div className="garage-content">
          {doesOwn ? (
            <>
              {/* Stats Bar */}
              <div className="stats-bar">
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <rect x="3" y="3" width="18" height="18" rx="2"/>
                      <path d="M3 9h18M9 21V9"/>
                    </svg>
                  </div>
                  <div className="stat-info">
                    <span className="stat-label">Tầng</span>
                    <span className="stat-value">{currentFloor}/{totalFloors}</span>
                  </div>
                </div>
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 002 12v4c0 .6.4 1 1 1h2"/>
                      <circle cx="7" cy="17" r="2"/>
                      <circle cx="17" cy="17" r="2"/>
                    </svg>
                  </div>
                  <div className="stat-info">
                    <span className="stat-label">Xe</span>
                    <span className="stat-value">{vehicles.length}</span>
                  </div>
                </div>
                {pricetakeout > 0 && (
                  <div className="stat-item">
                    <div className="stat-icon">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="12" cy="12" r="10"/>
                        <path d="M12 6v12M9 9h6M9 15h6"/>
                      </svg>
                    </div>
                    <div className="stat-info">
                      <span className="stat-label">Phí lấy xe</span>
                      <span className="stat-value">${formatNumber(pricetakeout)}</span>
                    </div>
                  </div>
                )}
              </div>

              {/* Floor selector if multiple floors */}
              {totalFloors > 1 && (
                <div className="floor-selector">
                  {Array.from({ length: totalFloors }, (_, i) => i + 1).map(floor => (
                    <button
                      key={floor}
                      className={`floor-btn ${currentFloor === floor ? 'active' : ''}`}
                      onClick={() => handleFloorChange(floor)}
                    >
                      Tầng {floor}
                    </button>
                  ))}
                </div>
              )}

              {/* Action Buttons */}
              <div className="action-buttons">
                <button className="btn btn-primary" onClick={handleEnterGarage} disabled={isLoading}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
                  </svg>
                  Vào Garage
                </button>
                <button className="btn btn-secondary" onClick={handleRefreshGarage} disabled={isLoading}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                  </svg>
                  Làm mới
                </button>
              </div>

              {/* Vehicles List */}
              <div className="vehicles-section">
                <div className="section-header">
                  <h2 className="section-title">Danh sách xe</h2>
                  <span className="vehicle-count">{vehicles.length} xe</span>
                </div>
                {vehicles.length > 0 ? (
                  <div className="vehicles-grid">
                    {vehicles.map((vehicle, index) => (
                      <VehicleCard
                        key={vehicle.plate || index}
                        vehicle={vehicle}
                        isSelected={selectedVehicle?.plate === vehicle.plate}
                        onClick={() => setSelectedVehicle(
                          selectedVehicle?.plate === vehicle.plate ? null : vehicle
                        )}
                        onTakeout={handleTakeoutVehicle}
                      />
                    ))}
                  </div>
                ) : (
                  <div className="empty-state">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                      <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 002 12v4c0 .6.4 1 1 1h2"/>
                      <circle cx="7" cy="17" r="2"/>
                      <circle cx="17" cy="17" r="2"/>
                    </svg>
                    <p>Chưa có xe nào trong garage</p>
                  </div>
                )}
              </div>
            </>
          ) : (
            /* Not owned - Show buy/preview options */
            <div className="not-owned-section">
              <div className="price-display">
                <span className="price-label">Giá mua garage</span>
                <span className="price-value">${formatNumber(price)}</span>
              </div>
              
              <div className="garage-features">
                <div className="feature">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>{garageInfo || 'Garage riêng với nhiều tính năng'}</span>
                </div>
                <div className="feature">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>Bảo vệ xe an toàn 24/7</span>
                </div>
                <div className="feature">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>Nhiều tầng để lưu trữ xe</span>
                </div>
              </div>

              <div className="action-buttons vertical">
                <button className="btn btn-success" onClick={handleBuyGarage} disabled={isLoading}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path>
                  </svg>
                  Mua Garage
                </button>
                <button className="btn btn-outline" onClick={handlePreviewGarage} disabled={isLoading}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    <path d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                  </svg>
                  Xem trước
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Loading Overlay */}
        {isLoading && (
          <div className="loading-overlay">
            <div className="spinner"></div>
            <span className="loading-text">Đang xử lý...</span>
          </div>
        )}
      </div>
    </div>
  )
}

export default Garage
