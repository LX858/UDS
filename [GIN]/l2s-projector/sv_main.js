let currentProjector = {
  url: null,
  type: null,
  presentationId: null,
  currentSlide: 1,
}

RegisterNetEvent('l2s-projector:server:project-start')
RegisterNetEvent('l2s-projector:server:project-stop')
RegisterNetEvent('l2s-projector:server:change-slide')
RegisterNetEvent('l2s-projector:server:request-sync')

on('l2s-projector:server:project-start', function (data) {
  if (typeof data === 'string') {
    const match = data.match(/\/presentation\/d\/([a-zA-Z0-9_-]+)/)
    if (match) {
      currentProjector.presentationId = match[1]
      currentProjector.currentSlide = 1
      currentProjector.type = 'slides'
      currentProjector.url = `https://docs.google.com/presentation/d/${match[1]}/embed?slide=id.p1`
    } else {
      currentProjector.url = data
      currentProjector.type = 'default'
      currentProjector.presentationId = null
      currentProjector.currentSlide = 1
    }
  } else if (typeof data === 'object' && data !== null) {
    currentProjector.url = data.url
    currentProjector.type = data.type || 'default'
    currentProjector.presentationId = data.presentationId || null
    currentProjector.currentSlide = data.currentSlide || 1
  }

  emitNet('l2s-projector:client:project-start', -1, currentProjector.url, currentProjector)
})

on('l2s-projector:server:change-slide', function (delta) {
  if (currentProjector.presentationId) {
    let nextSlide = (currentProjector.currentSlide || 1) + delta
    if (nextSlide < 1) nextSlide = 1
    currentProjector.currentSlide = nextSlide
    currentProjector.url = `https://docs.google.com/presentation/d/${currentProjector.presentationId}/embed?slide=id.p${nextSlide}`
    emitNet('l2s-projector:client:slide-updated', -1, currentProjector.url, currentProjector.currentSlide)
  }
})

on('l2s-projector:server:project-stop', function () {
  currentProjector = {
    url: null,
    type: null,
    presentationId: null,
    currentSlide: 1,
  }
  emitNet('l2s-projector:client:project-stop', -1)
})

on('l2s-projector:server:request-sync', function () {
  const src = source
  if (currentProjector.url) {
    emitNet('l2s-projector:client:project-start', src, currentProjector.url, currentProjector)
  }
})

