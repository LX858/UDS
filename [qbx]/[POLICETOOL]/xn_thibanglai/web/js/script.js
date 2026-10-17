const app = new Vue({
    el: '#app',

    data: {

        nomeRisorsa : GetParentResourceName(),

        schermata : 'license',

        domande : [],

        license : [],

        userLicense : [],

        currentQuestions : false,

        currentQuestion : {},

        selectedIndex : false,

        licenseSelected : false,

        correctAnswers : 0,

        descriptionTitle : "",

        puntiMinimi : 1,

        facendoTeoria : false,
        facendoPratica : false,
        countdownActive : false,
        countdownNumber : 5,

        config : {
            Lang: {
                dmv: "TRƯỜNG LÁI XE",
                ok: "Tiếp tục",
                point: "ĐIỂM SỐ",
                error: "LỖI",
                start_theory: "Bắt đầu thi lý thuyết",
                theory_before: "thi thực hành",
                start_practice: "Bắt đầu thi thực hành",
                test_passed: "Đã vượt qua bài thi!",
                already_done: "Bạn đã hoàn thành bài thi này!",
                money_error: "Bạn không đủ tiền để làm bài thi này! Bạn còn thiếu %s€",
                exam_title_bike: "ĐỀ THI BẰNG LÁI XE MÁY",
                exam_title_car: "ĐỀ THI BẰNG LÁI Ô TÔ",
                exam_title_truck: "ĐỀ THI BẰNG LÁI XE TẢI"
            }
        },

        contanti : 0,
        banca : 0,

        answerResult : null, // Thêm để lưu kết quả trả lời
        examTitle : "TRƯỜNG LÁI XE", // Tiêu đề bài thi hiện tại
        resultImage : null, // Ảnh kết quả thi
        errorMessage : null, // Thông báo lỗi
        practiceError : 0, // Số lỗi hiện tại khi thi thực hành
        practiceMaxError : 3, // Số lỗi tối đa
        showPracticeError : false, // Hiển thị UI số lỗi
        practiceTimeRemaining : 0, // Thời gian còn lại (giây)
        practiceTimeInterval : null, // Interval đếm ngược
        buttonCooldown : false, // Trạng thái cooldown
        cooldownTime : 0, // Thời gian cooldown còn lại
        confirmationType : null, // Loại xác nhận: 'practice' hoặc 'reissue'
        confirmationData : null // Dữ liệu cho xác nhận
    },

    computed: {
        formattedTime() {
            const minutes = Math.floor(this.practiceTimeRemaining / 60)
            const seconds = this.practiceTimeRemaining % 60
            return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
        }
    },

    methods: {
        postMessage(type, data) {
            $.post(`https://${this.nomeRisorsa}/${type}`, JSON.stringify(data));
        },
        
        startCooldown(seconds) {
            this.buttonCooldown = true
            this.cooldownTime = seconds
            
            const interval = setInterval(() => {
                this.cooldownTime--
                if(this.cooldownTime <= 0) {
                    clearInterval(interval)
                    this.buttonCooldown = false
                }
            }, 1000)
        },

        checkLicense(license) {
            console.log('Checking license:', license, 'userLicense:', this.userLicense)
            for(const[k,v] of Object.entries(this.userLicense)) {
                console.log('Comparing:', v.id, 'with', license)
                if(v.id == license) {
                    console.log('Match found! theory:', v.theory, 'practice:', v.practice)
                    if(v.theory && !v.practice) {
                        return "practice"
                    } else if(v.theory && v.practice) {
                        return "none"
                    } else {
                        return "theory"
                    }
                }
            }
            console.log('No match, returning false')
            return false;
        },

        getNotAttr() {
            var cosi = []
            for(const[k,v] of Object.entries(this.currentQuestions)) {
                if(!v.attr) {
                    cosi.push(k)
                }
            }
            return cosi
        },

        updateQuestion(disableupdate, controllocheck) {
            // Nếu chưa chọn câu trả lời và không phải đang xem kết quả thì báo lỗi
            if(!disableupdate && this.selectedIndex === false && !this.answerResult) {
                this.errorMessage = "⚠️ Vui lòng chọn câu trả lời trước khi xác nhận!"
                setTimeout(() => {
                    this.errorMessage = null
                }, 3000);
                return
            }
            
            // Nếu đã chọn câu trả lời và chưa xem kết quả, hiển thị kết quả
            if(!disableupdate && this.selectedIndex !== false && !this.answerResult) {
                const isCorrect = this.currentQuestion.options[this.selectedIndex].correct
                this.answerResult = {
                    correct: isCorrect
                }
                
                if(isCorrect) {
                    this.correctAnswers = this.correctAnswers + 1
                }
                
                // Dừng lại để người dùng xem kết quả
                return
            }
            
            // Khi nhấn tiếp tục sau khi xem kết quả hoặc gọi từ countdown
            this.answerResult = null
            this.selectedIndex = false
            $("input[type='radio']").prop('checked', false);

            if(this.getNotAttr().length == 0) {
                this.currentQuestion = false
                this.updateSchermata('risultato')
                this.selectedIndex = false
                if(this.correctAnswers >= this.puntiMinimi) {
                    this.postMessage('theoryOk', {
                        license : this.licenseSelected
                    })
                    this.licenseSelected = false
                    this.descriptionTitle = this.config.Lang.theory_success
                    this.resultImage = this.config.ResultImages?.pass || null
                } else {
                    this.descriptionTitle = this.config.Lang.theory_error
                    this.resultImage = this.config.ResultImages?.fail || null
                }
                for(const[k,v] of Object.entries(this.currentQuestions)) {
                    v.attr = false
                }
                return
            }
            var randomNumber = Math.floor(Math.random() * this.currentQuestions.length);
            for(const[k,v] of Object.entries(this.currentQuestions)) {
                if(k == randomNumber && v.attr) {
                    this.updateQuestion(true)
                    return
                }
            }
            for(const[k,v] of Object.entries(this.currentQuestions)) {
                if(k == randomNumber) {
                    v.attr = true
                    this.currentQuestion = this.currentQuestions[randomNumber]
                    this.descriptionTitle = this.currentQuestion.label
                }
            }
            this.updateSelectedQuestion(false)
        },  

        updateSelectedQuestion(index) {
            this.selectedIndex = index
        },

        startTheory(id, question) {
            if(this.buttonCooldown) {
                this.descriptionTitle = `Vui lòng đợi ${this.cooldownTime}s trước khi thực hiện lại!`
                setTimeout(() => {
                    this.descriptionTitle = ""
                }, 2000)
                return
            }
            this.startCooldown(3)
            // Gửi request check license về server
            this.postMessage('checkLicenseBeforeStart', {
                license: id,
                examType: 'theory'
            })
        },
        
        startTheoryConfirmed(id) {
            for(const[k,v] of Object.entries(this.license)) {
                if(v.id == id) {
                    if(this.contanti >= v.pricing.theory) {
                        this.postMessage('removeMoney', {
                            account : "money",
                            amount : v.pricing.theory
                        })
                    } else if(this.banca >= v.pricing.theory) {
                        this.postMessage('removeMoney', {
                            account : "bank",
                            amount : v.pricing.theory
                        })
                    } else {
                        var missingMoney = v.pricing.theory - this.contanti
                        this.descriptionTitle = this.config.Lang.money_error.replace("%s", missingMoney)
                        setTimeout(() => {
                            this.descriptionTitle  = ""
                        }, 5000);
                        return
                    }
                }
            }
            this.facendoTeoria = true
            this.facendoPratica = false
            this.licenseSelected = id+"dmv"
            this.correctAnswers = 0
            
            // Set exam title based on license type
            if(id === 'license_bike') {
                this.examTitle = this.config.Lang.exam_title_bike
            } else if(id === 'license_car') {
                this.examTitle = this.config.Lang.exam_title_car
            } else if(id === 'license_truck') {
                this.examTitle = this.config.Lang.exam_title_truck
            }
            
            this.updateSchermata('theory')
            // Lấy câu hỏi theo loại bằng
            var licenseQuestions = this.config.Question[id] || this.domande
            for(const[k,v] of Object.entries(licenseQuestions)) {
                v.attr = false
            }
            this.currentQuestions = licenseQuestions
            this.correctAnswers = 0
            
            // Bắt đầu preload ảnh và countdown
            this.preloadImagesAndStartCountdown()
        },
        
        preloadImagesAndStartCountdown() {
            // Preload tất cả ảnh trong bộ câu hỏi
            const imagesToLoad = []
            for(const[k,v] of Object.entries(this.currentQuestions)) {
                if(v.image) {
                    imagesToLoad.push(v.image)
                }
            }
            
            // Đếm ngược 5 giây
            this.countdownActive = true
            this.countdownNumber = 5
            
            // Preload ảnh trong background
            imagesToLoad.forEach(src => {
                const img = new Image()
                img.src = src
            })
            
            const countdownInterval = setInterval(() => {
                this.countdownNumber--
                if(this.countdownNumber <= 0) {
                    clearInterval(countdownInterval)
                    this.countdownActive = false
                    this.updateQuestion(true)
                }
            }, 1000)
        },

        startPractice(id) {
            if(this.buttonCooldown) {
                this.descriptionTitle = `Vui lòng đợi ${this.cooldownTime}s trước khi thực hiện lại!`
                setTimeout(() => {
                    this.descriptionTitle = ""
                }, 2000)
                return
            }
            this.startCooldown(3)
            
            // Tìm license và hiển thị popup xác nhận
            for(const[k,v] of Object.entries(this.license)) {
                if(v.id == id) {
                    this.showConfirmation(
                        'practice',
                        'XÁC NHẬN THI THỰC HÀNH',
                        `Bạn có muốn bắt đầu thi thực hành ${v.label}?`,
                        v.pricing.practice,
                        id
                    )
                    break
                }
            }
        },
        
        startPracticeConfirmed(id) {
            for(const[k,v] of Object.entries(this.license)) {
                if(v.id == id) {
                    if(this.contanti >= v.pricing.practice) {
                        this.postMessage('removeMoney', {
                            account : "money",
                            amount : v.pricing.practice
                        })
                    } else if(this.banca >= v.pricing.practice) {
                        this.postMessage('removeMoney', {
                            account : "bank",
                            amount : v.pricing.practice
                        })
                    } else {
                        var missingMoney = v.pricing.practice - this.contanti
                        this.descriptionTitle = this.config.Lang.money_error.replace("%s", missingMoney)
                        setTimeout(() => {
                            this.descriptionTitle  = ""
                        }, 5000);
                        return
                    }
                }
            }
            this.licenseSelected = id
            this.facendoTeoria = false 
            this.facendoPratica = true
            this.updateSchermata('license') // Chuyển về màn hình license
            $("#app").fadeOut(800) // Ẩn UI chính
            this.postMessage("close")
            this.postMessage('startPractice', {
                license : id
            })   
        },
        
        reissueLicense(license) {
            if(this.buttonCooldown) {
                this.descriptionTitle = `Vui lòng đợi ${this.cooldownTime}s trước khi thực hiện lại!`
                setTimeout(() => {
                    this.descriptionTitle = ""
                }, 2000)
                return
            }
            this.startCooldown(3)
            
            // Hiển thị popup xác nhận cấp lại
            this.showConfirmation(
                'reissue',
                'XÁC NHẬN CẤP LẠI BẰNG',
                `Bạn có muốn cấp lại ${license.label}?`,
                license.pricing.reissue,
                license
            )
        },
        
        reissueLicenseConfirmed(license, reissuePrice) {
            // Kiểm tra đủ tiền
            if(this.contanti >= reissuePrice) {
                this.postMessage('removeMoney', {
                    account : "money",
                    amount : reissuePrice
                })
            } else if(this.banca >= reissuePrice) {
                this.postMessage('removeMoney', {
                    account : "bank",
                    amount : reissuePrice
                })
            } else {
                var missingMoney = reissuePrice - this.contanti
                this.descriptionTitle = this.config.Lang.money_error.replace("%s", missingMoney)
                setTimeout(() => {
                    this.descriptionTitle = ""
                }, 5000);
                return
            }
            
            // Gọi server để cấp lại bằng
            this.postMessage('reissueLicense', {
                license : license
            })
        },

        updateDescription(msg) {
            this.descriptionTitle = msg
        },

        close() {
            this.facendoPratica = false
            this.facendoTeoria = false
            this.resultImage = null
            $("#app").fadeOut(800)
            this.postMessage("close")
        },

        updateSchermata(sch) {
            this.schermata = sch
            if(sch == "license") {
                this.updateDescription("")
                this.facendoTeoria = false
                this.facendoPratica = false
                this.countdownActive = false
                this.examTitle = this.config.Lang.dmv // Reset về tiêu đề mặc định
            }
            if(sch == "theory") {
                this.answerResult = null // Reset kết quả khi vào màn hình theory
            }
        },
        
        showConfirmation(type, title, message, price, data) {
            this.confirmationType = type
            this.confirmationData = data
            
            document.getElementById('confirm-title').textContent = title
            document.getElementById('confirm-message').textContent = message
            document.getElementById('confirm-price').textContent = `$${price.toLocaleString()}`
            document.getElementById('confirmation-popup').style.display = 'flex'
        },
        
        cancelConfirmation() {
            document.getElementById('confirmation-popup').style.display = 'none'
            this.confirmationType = null
            this.confirmationData = null
        },
        
        confirmPayment() {
            document.getElementById('confirmation-popup').style.display = 'none'
            
            if(this.confirmationType === 'practice') {
                // Gửi request check license về server
                this.postMessage('checkLicenseBeforeStart', {
                    license: this.confirmationData,
                    examType: 'practice'
                })
            } else if(this.confirmationType === 'reissue') {
                // Gửi request check license về server
                this.postMessage('checkLicenseBeforeReissue', {
                    license: this.confirmationData.id,
                    pricing: this.confirmationData.pricing.reissue
                })
            }
            
            this.confirmationType = null
            this.confirmationData = null
        }
    }

});

window.addEventListener('message', function(event) {
    var data = event.data;
    if (data.type === "OPEN") {
        $("#app").fadeIn(500)
        app.userLicense = data.licenses
        app.license = data.license
        app.updateSchermata('license')
    } else if(data.type === "UPDATE_LICENSE") {
        app.userLicense = data.licenses
    } else if(data.type === "START_THEORY_CONFIRMED") {
        app.startTheoryConfirmed(data.license)
    } else if(data.type === "START_PRACTICE_CONFIRMED") {
        app.startPracticeConfirmed(data.license)
    } else if(data.type === "REISSUE_LICENSE_CONFIRMED") {
        app.reissueLicenseConfirmed(data.license, data.reissuePrice)
    } else if(data.type === "DISPLAY_RISULTATO") {
        $("#app").fadeIn(800)
        app.correctAnswers = data.errori
        app.updateSchermata('risultato')
        app.facendoPratica = true
        app.facendoTeoria = false
        
        const maxErrors = data.maxErrors || 3
        
        console.log("Số lỗi:", data.errori, "Max lỗi:", maxErrors)
        
        if(data.errori > maxErrors) {
            // Rớt - Phân loại theo mức độ lỗi
            const errorDiff = data.errori - maxErrors
            console.log("Chênh lệch lỗi:", errorDiff)
            
            if(errorDiff <= 2) {
                app.descriptionTitle = app.config.Lang["practice_fail_light"] || app.config.Lang["practice_error"]
                console.log("Hiển thị: Rớt nhẹ")
            } else if(errorDiff <= 5) {
                app.descriptionTitle = app.config.Lang["practice_fail_medium"] || app.config.Lang["practice_error"]
                console.log("Hiển thị: Rớt nặng")
            } else {
                app.descriptionTitle = app.config.Lang["practice_fail_heavy"] || app.config.Lang["practice_error"]
                console.log("Hiển thị: Rớt thảm hại")
            }
            console.log("Thông báo:", app.descriptionTitle)
            app.resultImage = app.config.ResultImages?.fail || null
        } else {
            app.descriptionTitle = app.config.Lang["practice_success"]
            console.log("Hiển thị: Đậu")
            app.resultImage = app.config.ResultImages?.pass || null
            app.postMessage('practiceOk', {
                license : app.licenseSelected
            })
        }
    } else if(data.type === "SET_CONFIG") {
        app.config = data.config
        // Lưu tất cả câu hỏi theo loại bằng
        app.domande = data.config.Question
        app.config.Lang = app.config.Lang[app.config.Language]
        app.puntiMinimi = data.config.PuntiMinimi
    } else if(data.type === "SET_MONEY") {
        app.contanti = data.contanti,
        app.banca = data.banca
    } else if(data.type === "SHOW_PRACTICE_ERROR") {
        console.log("Nhận SHOW_PRACTICE_ERROR:", data)
        
        // Cập nhật UI với vanilla JS
        const hud = document.getElementById('practice-hud')
        const errorDisplay = document.getElementById('error-display')
        const timeDisplay = document.getElementById('time-display')
        const errorCircle = document.getElementById('error-circle')
        const errorIcon = document.getElementById('error-icon')
        
        if(hud) {
            hud.style.display = 'block'
            errorDisplay.textContent = `${data.error} / ${data.maxError}`
            
            // Format thời gian
            const minutes = Math.floor(data.timeLimit / 60)
            const seconds = data.timeLimit % 60
            timeDisplay.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
            
            // Màu sắc
            const borderColor = data.error >= data.maxError ? '#FF0000' : '#00FF7F'
            hud.style.borderColor = borderColor
            errorCircle.setAttribute('stroke', borderColor)
            errorIcon.setAttribute('fill', borderColor)
            errorDisplay.style.color = borderColor
            
            // Bắt đầu đếm ngược
            if(window.practiceInterval) {
                clearInterval(window.practiceInterval)
            }
            
            let timeRemaining = data.timeLimit
            window.practiceInterval = setInterval(() => {
                if(timeRemaining > 0) {
                    timeRemaining--
                    const mins = Math.floor(timeRemaining / 60)
                    const secs = timeRemaining % 60
                    timeDisplay.textContent = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
                    
                    // Đổi màu khi còn dưới 60s
                    const timeCircle = document.getElementById('time-circle')
                    const timeIcon = document.getElementById('time-icon')
                    if(timeRemaining < 60) {
                        timeCircle.setAttribute('stroke', '#FF0000')
                        timeIcon.setAttribute('fill', '#FF0000')
                        timeDisplay.style.color = '#FF0000'
                        timeDisplay.classList.add('animate-pulse')
                    }
                }
            }, 1000)
        }
        
        console.log("HUD đã hiển thị")
    } else if(data.type === "UPDATE_PRACTICE_ERROR") {
        const errorDisplay = document.getElementById('error-display')
        const errorCircle = document.getElementById('error-circle')
        const errorIcon = document.getElementById('error-icon')
        const hud = document.getElementById('practice-hud')
        
        if(errorDisplay) {
            errorDisplay.textContent = `${data.error} / ${data.maxError}`
            
            // Đổi màu khi đạt max lỗi
            const color = data.error >= data.maxError ? '#FF0000' : '#00FF7F'
            errorCircle.setAttribute('stroke', color)
            errorIcon.setAttribute('fill', color)
            errorDisplay.style.color = color
            if(hud) hud.style.borderColor = color
        }
    } else if(data.type === "HIDE_PRACTICE_ERROR") {
        const hud = document.getElementById('practice-hud')
        if(hud) hud.style.display = 'none'
        if(window.practiceInterval) {
            clearInterval(window.practiceInterval)
            window.practiceInterval = null
        }
    }
})

document.onkeyup = function (data) {
    if (data.key == 'Escape' && app.schermata == 'license') {
        $("#app").fadeOut(800)
        app.postMessage("close")
    }
};
