window.addEventListener('message', function(event) {
	$('.box-container').fadeIn()
	$('.box-container').css('animation', 'open .2s forwards ')
	step = {}
	max = event.data.lenght
	dif = event.data.difficulty
	let load
	count = 1
	now = 0
	for (var passkey = 1; passkey < max + 1; passkey++) {
		$('.box-pass').append('<i class="fa-sharp fa-solid fa-asterisk" id=\'pass\'></i>')
	}
	$('.text-pass').html('0/' + max)
	keysid()

	function keysid() {
		$('.container-wasd').html('')
		now = 0
		list = []
		var time = 0
		for (var buttuonkey = 1; buttuonkey < 5; buttuonkey++) {
			let button = 'b' + Math.floor(Math.random() * 4 + 1)
			if (button == 'b1') {
				list.push('W')
				$('.container-wasd').append('<div class="box-key" id="W">W</div>')
			} else {
				if (button == 'b2') {
					list.push('A')
					$('.container-wasd').append('<div class="box-key" id="A">A</div>')
				} else {
					if (button == 'b3') {
						list.push('S')
						$('.container-wasd').append('<div class="box-key" id="S">S</div>')
					} else {
						if (button == 'b4') {
							list.push('D')
							$('.container-wasd').append('<div class="box-key" id="D">D</div>')
						}
					}
				}
			}
		}
		var typetime = {
			'easy': 0.2,
			'normal': 0.25,
			'hard': 0.3
		};
		load = setInterval(() => {
			time += typetime[dif]
			time >= 100 && effectsound(false)
			now == 4 && clearInterval(load)
			$('#load').css('width', time + '%')
			inSegment = time >= 0 && time < 100
		}, 1)
	}
	document.addEventListener('keydown', keys)

	function keys(typekeys) {
		typekeys.code === 'KeyW' && (list[now] == 'W' ? currentkey() : ($('.box-key:nth-child(' + (now + 1) + ')').addClass('fail'), effectsound(false)))
		typekeys.code === 'KeyA' && (list[now] == 'A' ? currentkey() : ($('.box-key:nth-child(' + (now + 1) + ')').addClass('fail'), effectsound(false)))
		typekeys.code === 'KeyS' && (list[now] == 'S' ? currentkey() : ($('.box-key:nth-child(' + (now + 1) + ')').addClass('fail'), effectsound(false)))
		typekeys.code === 'KeyD' && (list[now] == 'D' ? currentkey() : ($('.box-key:nth-child(' + (now + 1) + ')').addClass('fail'), effectsound(false)))
	}

	function currentkey() {
		if (inSegment) {
			const a2 = new Audio()
			a2.src = './Click.ogg'
			a2.play()
			a2.volume = 0.6
			now = now + 1
			$('.box-key:nth-child(' + now + ')').addClass('active')
		}
		if (now == 4) {
			if (count < max) {
				const a1 = new Audio()
				setTimeout(function() {
					$('.box-key').removeClass('active')
					a1.src = './fail.mp3'
					a1.play()
					a1.volume = 0.6
					$('#pass:nth-child(' + count + ')').addClass('activepass')
					count = count + 1
					$('.text-pass').html(count + '/' + max)
					keysid()
				}, 500)
			} else {
				effectsound(true)
			}
		}
	}

	function effectsound(sound) {
		if (sound) {
			const a3 = new Audio()
			a3.src = './open.mp3'
			a3.play()
			a3.volume = 1
		} else {
			const a4 = new Audio()
			a4.src = './error.mp3'
			a4.play()
			a4.volume = 0.4

			$('.loadss').css('background', 'linear-gradient(-175deg, var(--bglgd3) 0%, var(--bglgd4) 100%)')

		}

		setTimeout(function() {
			$('.box-container').fadeOut()
			$('.box-container').css('animation', 'quit .2s forwards ')
	
			$.post('https://1307_MinigameWASD/result', JSON.stringify({
				result: sound
			}))
		}, 800)
		clearInterval(load)

		
		setTimeout(function() {
			location.reload()
		}, 1400)
	}
})