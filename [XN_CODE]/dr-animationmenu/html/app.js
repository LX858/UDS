var resourceName = "dr-animationmenu";
if (window.GetParentResourceName) {
	resourceName = window.GetParentResourceName();
}
window.postNUI = async (name = "defaultName", data = {}) => {
	try {
		const response = await fetch(`https://${resourceName}/${name}`, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify(data),
		});
		return !response.ok ? null : response.json();
	} catch (error) {
		console.error(error);
	}
};


const app = Vue.createApp({

	data() {
		return {
			general: {
				show: false,
				category: "normal",
				page: 1,
				search: "",
				previewDisable: false,
			},
			getRequestData: {
				show : false,
				whoSend : "",
				anim: {},
			},
			categories : [
				{ name: "Normal", value: "normal", image: "./img/normal.png" },
				{ name: "Expression", value: "expression", image: "./img/expression.png" },
				{ name: "Walk", value: "walk", image: "./img/walk.png" },
				{ name: "Dance", value: "dance", image: "./img/dance.png" },
				{ name: "Prop", value: "prop", image: "./img/prop.png" },
				{ name: "Shared", value: "shared", image: "./img/shared.png" },
			],
			animationList: [],
			favAnims: [],
			shortcutAnims: [],
			translate: {},

			showedAnims: [],
			draggedItem: {},
			visibleItems: [],

			itemHeightVh: 19.65, // Her bir item'ın yüksekliği (vh cinsinden)
			itemWidthVh: 16.2, // Her bir item'ın genişliği (vh cinsinden)
			containerHeightVh: 61, // Scrollable container'ın yüksekliği (vh cinsinden)
			containerWidthVh: 120, // Scrollable container'ın genişliği (vh cinsinden)

			itemHeightVh2: 16, // Her bir item'ın yüksekliği (vh cinsinden)
			itemWidthVh2: 12.9, // Her bir item'ın genişliği (vh cinsinden)
			containerHeightVh2: 50, // Scrollable container'ın yüksekliği (vh cinsinden)
			containerWidthVh2: 55, // Scrollable container'ın genişliği (vh cinsinden)

			scrollTopVh: 0, // Scroll top pozisyonu (vh cinsinden)
			totalHeightVh: 0, // Toplam listenin yüksekliği (vh cinsinden)
			startIndex: 0,
			endIndex: 0,
		};
	},
	methods: {

		getItemCountInSameCategory(category) {
			if (category == "favorites") {
				return this.favAnims.length;
			}
			return this.animationList.filter((item) => {
				return item.category == category;
			}).length;
		},

		handleImageError(event){
			event.target.src = "./img/question.png";
		},

		checkAnimInFav(anim) {
			let favIndex = this.favAnims.findIndex(x => x.name == anim.name);
			if (favIndex != -1) {
				return true;
			}
			return false;
		},

		addFav(anim) {
			event.stopPropagation();
			// add anim to fav list if not exist
			let favIndex = this.favAnims.findIndex(x => x.name == anim.name);
			if (favIndex == -1) {
				this.favAnims.push(anim);
			}

			// save local storage
			localStorage.setItem("favoriteAnimations", JSON.stringify(this.favAnims));
		},

		deleteFav(anim) {
			event.stopPropagation();
			// delete anim from fav list
			let favIndex = this.favAnims.findIndex(x => x.name == anim.name);
			if (favIndex != -1) {
				this.favAnims.splice(favIndex, 1);
			}

			// save local storage
			localStorage.setItem("favoriteAnimations", JSON.stringify(this.favAnims));
		},
	

		onScroll() {
			const container = this.$refs.animList;
			if (!container) {
			  // Eğer referans tanımlı değilse metottan çık
			  return;
			}
		  	this.scrollTopVh = (container.scrollTop / container.clientHeight) * 100;
		  	this.updateVisibleItems();
		},

		onScroll2() {
			const container = this.$refs.animList2;
			if (!container) {
			  // Eğer referans tanımlı değilse metottan çık
			  return;
			}
		  	this.scrollTopVh = (container.scrollTop / container.clientHeight) * 100;
		  	this.updateVisibleItems();
		},

		updateVisibleItems() {
			// Nếu đang tìm kiếm, không cập nhật visibleItems khi scroll
			if (this.general.search && this.general.search.trim() !== "") {
				return;
			}

			const viewportHeight = window.innerHeight; // Viewport'un yüksekliği piksel cinsinden
			if (this.general.page == 1) {
				containerHeightPx = (this.containerHeightVh / 100) * viewportHeight; // Container'ın yüksekliği piksel cinsinden
				containerWidthPx = (this.containerWidthVh / 100) * viewportHeight; // Container'ın genişliği piksel cinsinden
				itemWidthPx = (this.itemWidthVh / 100) * viewportHeight; // Bir öğenin genişliği piksel cinsinden
				itemHeightPx = (this.itemHeightVh / 100) * viewportHeight; // Her bir item'ın yüksekliği piksel cinsinden
			} else {
				containerHeightPx = (this.containerHeightVh2 / 100) * viewportHeight; // Container'ın yüksekliği piksel cinsinden
				containerWidthPx = (this.containerWidthVh2 / 100) * viewportHeight; // Container'ın genişliği piksel cinsinden
				itemWidthPx = (this.itemWidthVh2 / 100) * viewportHeight; // Bir öğenin genişliği piksel cinsinden
				itemHeightPx = (this.itemHeightVh2 / 100) * viewportHeight; // Her bir item'ın yüksekliği piksel cinsinden
			}
			// Container'ın toplam satır ve sütun sayısını hesaplama
			const totalRowsInContainer = Math.floor(containerHeightPx / itemHeightPx); // Toplam satır sayısı
			const totalColsInContainer = Math.floor(containerWidthPx / itemWidthPx); // Toplam sütun sayısı
			// Ekranda görünen toplam öğe sayısını hesaplama
			const totalItemsInContainer = totalRowsInContainer * totalColsInContainer;
			// Scroll pozisyonu hesaplama
			const scrollTopPx = (this.scrollTopVh / 100) * viewportHeight; // Scroll pozisyonu piksel cinsinden
			const startRow = Math.floor(scrollTopPx / itemHeightPx); // İlk görünen satırın indeksi
			// İlk ve son görünen öğelerin indeksini hesaplama

			this.startIndex = 0 ;

			if (this.general.page == 1) {
				this.endIndex = (startRow / 3 + 2) * (totalItemsInContainer * 2);
			} else {
				this.endIndex = (startRow / 7 + 1) * (totalItemsInContainer * 2);
			}
			// endIndex, toplam öğe sayısından büyükse, toplam öğe sayısına eşitliyoruz
			if (this.endIndex > this.showedAnims.length) {
				this.endIndex = this.showedAnims.length;
			}
			// VisibleItems'ı doğrudan güncelle
			this.visibleItems = this.showedAnims.slice(this.startIndex, this.endIndex);
		},

		// Function to initialize drag and drop functionality
		initializeDragAndDrop() {
			const self = this;
			this.showedAnims.forEach((item) => {
				$(`#${item.name}`).draggable({
					helper: "clone", // Sürükleme sırasında bir kopya oluşturur
					start: function (event, ui) {

						self.draggedItem = item // Sürüklenen öğeyi klonla
						ui.helper.css("cursor", "move"); // Sürüklenen öğe için cursor değişikliği
						ui.helper.css('z-index', 1000000);
					},
				});
			});
			if (this.general.page == 1) {

				$('.animItemShortCuts').each(function() {
					$(this).droppable({
						drop: function (event, ui) {
							// Drop işlemi gerçekleştiğinde
	
							let shortcutId = this.id.replace("shortcutBig+", "");
							self.addShortcut(shortcutId, self.draggedItem);
						}
					});
				});
			}else {
				$('.smallAnimItemFavorite').each(function() {
					$(this).droppable({
						drop: function (event, ui) {
							// Drop işlemi gerçekleştiğinde
	
							let shortcutId = this.id.replace("shortcutSmall+", "");
							self.addShortcut(shortcutId, self.draggedItem);
						}
					});
				});
			}
			
		},

		addShortcut(shortcutId, anim) {
		
			let shortcutIndex = this.shortcutAnims.findIndex(x => x.shortcutId == shortcutId);
			if (shortcutIndex != -1) {
				this.shortcutAnims[shortcutIndex] = {
					name: anim.name,
					label: anim.label,
					image: anim.image,
					shortcutId: shortcutId,
				};
			} else {
				this.shortcutAnims.push({
					name: anim.name,
					label: anim.label,
					image: anim.image,
					shortcutId: shortcutId,
				});
			}

			localStorage.setItem("shortcutAnimsx", JSON.stringify(this.shortcutAnims));
		},

		deleteShortcut(shortcutId) {
			let shortcutIndex = this.shortcutAnims.findIndex(x => x.shortcutId == shortcutId);
			if (shortcutIndex != -1) {
				this.shortcutAnims[shortcutIndex] = {
					name: "empty",
					label: "Empty",
					image: "empty.png",
					shortcutId: shortcutId,
				};
				localStorage.setItem("shortcutAnimsx", JSON.stringify(this.shortcutAnims));
			}
		},

		fastUseAnim(emote) {
			postNUI("playEmote", emote.name);
		},

		previewUseAnim(emote) {
			postNUI("previewEmote", emote.name);
		},

		changePage(page) {
			this.general.page = page;
		},

		changeCategory(category) {
			this.general.category = category;
			if (category == "favorites") {
				this.showedAnims = this.favAnims;
			}else{
				let filteredAnims = this.animationList.filter((item) => {
					return item.category == category;
				});
				// Sort HOT emotes to the top
				this.showedAnims = filteredAnims.sort((a, b) => {
					if (a.hot && !b.hot) return -1;
					if (!a.hot && b.hot) return 1;
					return 0;
				});
			}

			this.totalHeightVh = this.showedAnims.length * this.itemHeightVh;
			this.updateVisibleItems();

			setTimeout(() => {
				this.initializeDragAndDrop();

				const animListElement = this.$refs.animList;
				if (animListElement) {
					animListElement.scrollTop = 0;
				}

				const animListElement2 = this.$refs.animList2;
				if (animListElement2) {
					animListElement2.scrollTop = 0;
				}
					
					
			}, 200);
		},

		keyHandler(event) {
			if (event.which == 27) {
				if (this.general.show) {
					this.general.show = false;
					postNUI("closeMenu");
				}
			}
		},

		closeMenu(){
			this.general.show = false;
			postNUI("closeMenu");
		},


		loaded(){
			axios.post(`https://${resourceName}/loaded`, {}).then((response) => {
				if (!response || !response.data) return;
				
				this.animationList = response.data.animationList;
				this.translate = response.data.locales;
				if (this.animationList.length > 0) {
					this.animationList.forEach((item, index) => {
						this.animationList[index].showImage = true;
						if (item.category == "expression") {
							this.animationList[index].image = `https://ak4y.github.io/expression2_indir/value=${item.anim}.webp`
						} else if (item.category == "walk") {
							this.animationList[index].image = `https://ak4y.github.io/walks_indir/value=${item.anim}.webp`
						} else if (item.category == "dance") {
							this.animationList[index].image = `https://ak4y.github.io/dance_indir/dict=${item.dict}==anim=${item.anim}.webp`
						}else {
							this.animationList[index].image = `https://ak4y.github.io/emote_indir/id=${item.name}.webp`
						}
					});
					this.changeCategory("normal");
				}
				// this.initializeDragAndDrop();
			}).catch((error) => {
				console.error("Error loading data:", error);
			});
		},
	},
	computed: {

		getTranslate() {
			return this.translate || {};
		},

		getshortcutAnims() {
			// if hav anims < 7 then fill with empty
			let shortcutAnims = this.shortcutAnims;
			let emptyAnims = 7 - shortcutAnims.length;
			if (emptyAnims > 0) {
				for (let i = 0; i < emptyAnims; i++) {
					shortcutAnims.push({ name: "empty", label: "Empty", image: "empty.png", shortcutId: i+1 });
				}
			}
			return shortcutAnims;
		},
		getCategories() {
			return this.categories;
		},

		getAnimList() {
			return this.showedAnims
		},


		getVisibleItems() {	
			return this.visibleItems;
		},
		
		
	},
	watch: {
		"general.search": function (val) {
			// Nếu ô tìm kiếm trống, khôi phục lại lazy loading
			if (!val || val.trim() === "") {
				this.updateVisibleItems();
				return;
			}

			// Nếu có từ khóa tìm kiếm, hiển thị tất cả kết quả
			if (this.general.category == "favorites") {
				this.visibleItems = this.favAnims.filter((item) => {
					return (item.label.toLowerCase().includes(val.toLowerCase()) ||  item.name.toLowerCase().includes(val.toLowerCase()) );
				});
			}else{
				this.visibleItems = this.animationList.filter((item) => {
					return (item.label.toLowerCase().includes(val.toLowerCase()) ||  item.name.toLowerCase().includes(val.toLowerCase()) ) && item.category == this.general.category;
				});
			}
		},
	},
	mounted() {
		// Load dữ liệu trước khi hiển thị UI
		this.loaded();
		this.shortcutAnims = JSON.parse(localStorage.getItem("shortcutAnimsx")) || [];
		this.favAnims = JSON.parse(localStorage.getItem("favoriteAnimations")) || [];
		
		window.addEventListener("message", (event) => {
			if (event.data.action == "display") {
				// Đảm bảo chỉ hiển thị UI khi đã có dữ liệu
				if (event.data.payload) {
					// Kiểm tra nếu dữ liệu đã sẵn sàng
					if (this.animationList.length > 0 && Object.keys(this.translate).length > 0) {
						this.general.show = true;
						setTimeout(() => {
							this.initializeDragAndDrop();
						}, 500);
					} else {
						// Nếu chưa có dữ liệu, đợi và thử lại
						console.log("Waiting for data to load...");
						const checkDataInterval = setInterval(() => {
							if (this.animationList.length > 0 && Object.keys(this.translate).length > 0) {
								clearInterval(checkDataInterval);
								this.general.show = true;
								setTimeout(() => {
									this.initializeDragAndDrop();
								}, 500);
							}
						}, 100);
						
						// Timeout sau 5 giây nếu vẫn không có dữ liệu
						setTimeout(() => {
							clearInterval(checkDataInterval);
						}, 5000);
					}
				} else {
					this.general.show = false;
				}
			}else if (event.data.action == "getRequest") {
				this.getRequestData.show = true;
				this.getRequestData.whoSend = event.data.senderData.senderName;
				this.getRequestData.anim.label = event.data.senderData.emoteLabel;

				// close request after 5 seconds
				setTimeout(() => {
					this.getRequestData.show = false;
					this.getRequestData.whoSend = "";
					this.getRequestData.anim = {};
				}, 5000);
			}else if (event.data.action == "closeRequest") {
				this.getRequestData.show = false;
				this.getRequestData.whoSend = "";
				this.getRequestData.anim = {};
			}else if (event.data.action == "playerUseShortcut") {
				let usedKey = event.data.usedKey;
				// check if key is valid in shortcutAnims
				let shortcutIndex = this.shortcutAnims.findIndex(x => x.shortcutId == usedKey);
				if (shortcutIndex != -1) {
					let anim = this.shortcutAnims[shortcutIndex];
					if (anim.name != "empty") {
						postNUI("playEmote", anim.name);
					}
				}
			}
		});
		window.addEventListener("keyup", this.keyHandler);
		// window.postNUI("getData");
		
		// Thêm class loaded vào body sau khi app đã mount
		setTimeout(() => {
			document.body.classList.add('loaded');
		}, 100);
	},

	
});

app.mount("#app");
