var table = []
var windowIsOpened = false
var selectedWindow = "none"
var item = null
var currentSociety = null
var societyCurrentPage = 1
var myInvoicesCurrentPage = 1

// Windows
window.addEventListener('message', function(event) {
	item = event.data;
	switch (event.data.action) {
		case 'mainmenu':
			if (!windowIsOpened) {
				var popup = new Audio('popup.mp3');
				popup.volume = 0.4;
				popup.play();

				windowIsOpened = true
				
				if (event.data.society == true){
				row = `	<div class="d-flex justify-content-center">
							<div class="col col-md-4">
								<div class="card h-100">
								  <div class="card-body text-center mainmenu-subcard" id="menuMyInvoices" style="background-color: #292a31; color: #e6e6e6;">
								    <span class="card-title" style="font-size: 35px;"><i class="fas fa-user"></i></span>
								    <p class="card-text">Cá nhân</p>
								  </div>
								</div>
							</div>
							<div class="col col-md-4" style="margin-left: 25px;">
								<div class="card h-100">
								  <div class="card-body text-center mainmenu-subcard" id="menuSocietyInvoices" style="background-color: #292a31; color: #e6e6e6;">
								    <span class="card-title" style="font-size: 35px;"><i class="fas fa-building"></i></span>
								    <p class="card-text">Công ty</p>
								  </div>
								</div>
								</div>
							</div>

						  `
				} else if(event.data.create & !event.data.society){
					row = `	<div class="d-flex justify-content-center">
								<div class="col col-md-4">
									<div class="card h-100">
									  <div class="card-body text-center mainmenu-subcard" id="menuMyInvoices" style="background-color: #292a31; color: #e6e6e6;">
									    <span class="card-title" style="font-size: 35px;"><i class="fas fa-user"></i></span>
									    <p class="card-text">Cá nhân</p>
									  </div>
									</div>
								</div>

							</div>
						  `
				} else if(!event.data.create & !event.data.society){
					row = `	<div class="d-flex justify-content-center">
								<div class="col col-md-4">
									<div class="card h-100">
									  <div class="card-body text-center mainmenu-subcard" id="menuMyInvoices" style="background-color: #292a31; color: #e6e6e6;">
									    <span class="card-title" style="font-size: 35px;"><i class="fas fa-user"></i></span>
									    <p class="card-text">Cá nhân</p>
									  </div>
									</div>
								</div>
							</div>
						  `
				}

				$(".mainmenu").fadeIn();
				$("#mainMenuData").html(row);
				selectedWindow = "mainMenu"
			}
			break
		case 'myinvoices':
			// Clear existing DataTables and modals first
			for(var i=table.length-1; i>=0; i--) {
				if(table[i]) {
					table[i].destroy();  
					table.splice(i, 1);
				}
			}
			$(".modal").remove();
			
			if (!windowIsOpened) {
				var popup = new Audio('popup.mp3');
				popup.volume = 0.4;
				popup.play();
				
				windowIsOpened = true;
				selectedWindow = "myinvoices";
			}

				var row = "";
			myInvoicesCurrentPage = event.data.currentPage || 1;
				// Update pagination controls
				if (event.data.totalPages > 1) {
					$("#myInvoicesPaginationControls").show();
					$("#myInvoicesCurrentPageSpan").text(`${event.data.currentPage} / ${event.data.totalPages}`);
					
					// Update prev button
					if (event.data.currentPage <= 1) {
						$("#myInvoicesPrevPage").addClass('disabled');
					} else {
						$("#myInvoicesPrevPage").removeClass('disabled');
					}
					
					// Update next button  
					if (event.data.currentPage >= event.data.totalPages) {
						$("#myInvoicesNextPage").addClass('disabled');
					} else {
						$("#myInvoicesNextPage").removeClass('disabled');
					}
				} else {
					$("#myInvoicesPaginationControls").hide();
				}

				for(var i=0; i<event.data.invoices.length; i++)
				{
					var invoices = event.data.invoices[i];
					var tablestatus = "";

					if (invoices.status == 'paid') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-success" style="font-size: 14px;"><i class="fas fa-check-circle"></i> ĐÃ THANH TOÁN</span></td>';
						modalstatus = '<span class="badge bg-success" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-check-circle"></i> ĐÃ THANH TOÁN</span>';
						payment_status = `<span style="font-size: 20px; color: #e6e6e6; text-transform: uppercase; font-weight: 600;">ĐÃ TRẢ TIỀN: ${invoices.paid_date}</span>`;
					}
					else if (invoices.status == 'unpaid') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-danger" style="font-size: 14px;"><i class="fas fa-times-circle"></i> CHƯA THANH TOÁN</span></td>';
						modalstatus = '<span class="badge bg-danger" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-times-circle"></i> CHƯA THANH TOÁN</span>';
						payment_status = `<button type="button" id="" class="btn btn-blue flex-grow-1 payInvoice" style="border-radius: 10px; flex-basis: 100%;" data-invoiceId="${invoices.id}" data-invoiceMoney="${invoices.invoice_value}" data-bs-dismiss="modal"><i class="fas fa-shopping-bag"></i> THANH TOÁN ${invoices.invoice_value.toLocaleString()}💵</button>`;
					}
					else if (invoices.status == 'autopaid') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-info" style="font-size: 14px;"><i class="fas fa-clock"></i> TỰ ĐỘNG THANH TOÁN</span></td>';
						modalstatus = '<span class="badge bg-info" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-clock"></i> TỰ ĐỘNG THANH TOÁN</span>';
						payment_status = `<span style="font-size: 20px; color: #e6e6e6; text-transform: uppercase; font-weight: 600;">TỰ ĐỘNG THANH TOÁN BẬT: ${invoices.paid_date}</span>`;
					}
					else if (invoices.status == 'cancelled') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-secondary" style="font-size: 14px;"><i class="fas fa-minus-circle"></i> HỦY</span></td>';
						modalstatus = '<span class="badge bg-secondary" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-minus-circle"></i> HỦY</span>';
						payment_status = '<span style="font-size: 20px; color: #e6e6e6; text-transform: uppercase; font-weight: 600;">HỦY</span>'
					}

					if (invoices.limit_pay_date == 'N/A') {
						limit_pay_date = ''
					} else {
						limit_pay_date = `<h6 class="" id="" style="color: #9e9e9e;">Hết hạn vào lúc: ${invoices.limit_pay_date}</h6>`
					}

					row += `
						<tr>
							<td class="text-center align-middle">${invoices.id}</td>
							${tablestatus}
							<td class="text-center align-middle">${invoices.society_name}</td>
							<td class="text-center align-middle">${invoices.item}</td>
							<td class="text-center align-middle">${invoices.invoice_value.toLocaleString()}$</td>
							<td class="text-center align-middle"><button type="button" class="btn btn-blue showInvoice" style="border-radius: 10px; flex-basis: 100%;" data-toggle="modal" data-target="#showInvoiceModal${invoices.id}" data-invoiceId="${invoices.id}""><i class="fas fa-eye"></i> XEM</button></td>
						</tr>
					`;

					var modal = `<div class="modal fade" id="showInvoiceModal${invoices.id}" tabindex="-1">
									<div class="modal-dialog modal-dialog-centered">
										<div class="modal-content myinvoices_modal-content">
											<div class="modal-body p-4">
												<span class="menutitle">Hóa đơn #${invoices.id}</span>
												${modalstatus}
												<h6 class="" id="" style="color: #9e9e9e;">Ngày viết hóa đơn: ${invoices.sent_date}</h6>
												${limit_pay_date}
												<h6 class="" id="" style="color: #9e9e9e; margin-top: 20px;">Người nhận: <span style="color: #9e9e9e;">${invoices.receiver_name}</span></h6>
												<h6 class="" id="" style="color: #9e9e9e;">Người gửi: <span style="color: #9e9e9e;">${invoices.author_name}</span></h6>
												<hr>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px;">${invoices.item}</span> <span class="" id="" style="color: #e6e6e6; font-size: 18px;">${Math.round(invoices.invoice_value - Math.round(invoices.invoice_value * (event.data.VAT/100))).toLocaleString()} $</span>
												</div>
												<hr>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px; font-weight: 700;">Tổng phụ</span> <span class="" id="" style="color: #e6e6e6; font-size: 18px;">${Math.round(invoices.invoice_value - Math.round(invoices.invoice_value * (event.data.VAT/100))).toLocaleString()} $</span>
												</div>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px; font-weight: 700;">VAT (${event.data.VAT}%)</span> <span class="" id="" style="color: #e6e6e6; font-size: 18px;">${Math.round(invoices.invoice_value * (event.data.VAT/100)).toLocaleString()} $</span>
												</div>
												<br>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px; font-weight: 700;">Toàn bộ</span> <span class="" id="" style="color: #e6e6e6; font-size: 18px;">${Math.round(invoices.invoice_value).toLocaleString()} $</span>
												</div>
												<br>
												<div class="d-flex justify-content-center">
													${payment_status}
												</div>
												<br>
											</div>
										</div>
									</div>
								</div>
								`;
					$("body").append(modal);
				}
			$("#myInvoicesData").html(row);

			// Always show the window first
			if (!$(".myinvoices").is(':visible')) {
				$(".myinvoices").fadeIn();
			}

			// Don't use DataTable when pagination is active to avoid layout conflicts
			if (event.data.totalPages <= 1 && event.data.invoices.length > 0) {
				// Only initialize DataTable for single page datasets
				setTimeout(function() {
					const myinvoices = document.getElementById('myInvoices');
					if (myinvoices && !myinvoices.classList.contains('dataTable-table')) {
						table.push(new simpleDatatables.DataTable(myinvoices, {
							searchable: true,
							perPageSelect: false,
							perPage: 5,
						}));
					}
				}, 100);
			}
			
			break
		case 'createinvoice':
			if (!windowIsOpened) {
				windowIsOpened = true
				$("#sendInvoiceSubtitle").html(event.data.society);
				
				// Khôi phục dữ liệu từ localStorage
				var savedData = localStorage.getItem('lastInvoiceData');
				if (savedData) {
					try {
						var lastInvoice = JSON.parse(savedData);
						$("#invoice_item").val(lastInvoice.item || "");
						$("#invoice_value").val(lastInvoice.value || "");
						$("#invoice_notes").val(lastInvoice.notes || "");
					} catch(e) {
						console.error("Error loading saved invoice data:", e);
					}
				}
				
				$(".sendinvoice").fadeIn();
				selectedWindow = "createinvoice"
			}
			break
		case 'societyinvoices':
			// Clear existing DataTables and modals first
			for(var i=table.length-1; i>=0; i--) {
				if(table[i]) {
					table[i].destroy();  
					table.splice(i, 1);
				}
			}
			$(".modal").remove();
			
			if (!windowIsOpened) {
				var popup = new Audio('popup.mp3');
				popup.volume = 0.4;
				popup.play();
				
				windowIsOpened = true;
				selectedWindow = "societyinvoices";
			}

			var row = "";
			currentSociety = event.data.invoices.length > 0 ? event.data.invoices[0].society_name : '';
			societyCurrentPage = event.data.currentPage || 1;

			// Update statistics
			$("#societyInvoicesTitle").html(currentSociety);
			$("#totalInvoices").html(event.data.totalInvoices);
			$("#totalIncome").html(`${event.data.totalIncome.toLocaleString()}💵`);
			$("#unpaidInvoices").html(event.data.totalUnpaid);
			$("#awaitedIncome").html(`${event.data.awaitedIncome.toLocaleString()}💵`);

			// Update pagination controls
			if (event.data.totalPages > 1) {
				$("#paginationControls").show();
				$("#currentPageSpan").text(`${event.data.currentPage} / ${event.data.totalPages}`);
				
				// Update prev button
				if (event.data.currentPage <= 1) {
					$("#prevPage").addClass('disabled');
				} else {
					$("#prevPage").removeClass('disabled');
				}
				
				// Update next button  
				if (event.data.currentPage >= event.data.totalPages) {
					$("#nextPage").addClass('disabled');
				} else {
					$("#nextPage").removeClass('disabled');
				}
			} else {
				$("#paginationControls").hide();
			}

				for(var i=0; i<event.data.invoices.length; i++)
				{
					var invoices = event.data.invoices[i];
					var tablestatus = "";

					if (invoices.status == 'paid') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-success" style="font-size: 14px;"><i class="fas fa-check-circle"></i> ĐÃ THANH TOÁN</span></td>';
						modalstatus = '<span class="badge bg-success" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-check-circle"></i> ĐÃ THANH TOÁN</span>';
						payment_status = `<span style="font-size: 20px; color: #e6e6e6; text-transform: uppercase; font-weight: 600;">ĐÃ TRẢ TIỀN: ${invoices.paid_date}</span>`;
					}
					else if (invoices.status == 'unpaid') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-danger" style="font-size: 14px;"><i class="fas fa-times-circle"></i> CHƯA THANH TOÁN</span></td>';
						modalstatus = '<span class="badge bg-danger" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-times-circle"></i> CHƯA THANH TOÁN</span>';
						payment_status = `<button type="button" id="" class="btn btn-red flex-grow-1 cancelInvoice" style="border-radius: 10px; flex-basis: 100%;" data-invoiceId="${invoices.id}" data-invoiceMoney="${invoices.invoice_value}" data-bs-dismiss="modal"><i class="fas fa-times-circle"></i> HỦY HÓA ĐƠN</button>`;
					}
					else if (invoices.status == 'autopaid') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-info" style="font-size: 14px;"><i class="fas fa-clock"></i> TỰ ĐỘNG THANH TOÁN</span></td>';
						modalstatus = '<span class="badge bg-info" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-clock"></i> TỰ ĐỘNG THANH TOÁN</span>';
						payment_status = `<span style="font-size: 20px; color: #e6e6e6; text-transform: uppercase; font-weight: 600;">TỰ ĐỘNG THANH TOÁN BẬT: ${invoices.paid_date}</span>`;
					}
					else if (invoices.status == 'cancelled') {
						tablestatus = '<td class="text-center align-middle"><span class="badge bg-secondary" style="font-size: 14px;"><i class="fas fa-minus-circle"></i> HỦY</span></td>';
						modalstatus = '<span class="badge bg-secondary" style="position: absolute; right: 5%; top: 5%; font-size: 18px;"><i class="fas fa-minus-circle"></i> HỦY</span>';
						payment_status = '<span style="font-size: 20px; color: #e6e6e6; text-transform: uppercase; font-weight: 600;">HỦY</span>'
					}

					if (invoices.limit_pay_date == 'N/A') {
						limit_pay_date = ''
					} else {
						limit_pay_date = `<h6>Hết hạn vào lúc: ${invoices.limit_pay_date}</h6>`
					}

					row += `
						<tr>
							<td class="text-center align-middle">${invoices.id}</td>
							${tablestatus}
							<td class="text-center align-middle">${invoices.receiver_name}</td>
							<td class="text-center align-middle">${invoices.item}</td>
							<td class="text-center align-middle">${invoices.invoice_value.toLocaleString()}$</td>
							<td class="text-center align-middle"><button type="button" class="btn btn-blue showInvoice" style="border-radius: 10px; flex-basis: 100%;" data-toggle="modal" data-target="#showInvoiceModal${invoices.id}" data-invoiceId="${invoices.id}""><i class="fas fa-eye"></i> XEM</button></td>
						</tr>
					`;

					var modal = `<div class="modal fade" id="showInvoiceModal${invoices.id}" tabindex="-1">
									<div class="modal-dialog modal-dialog-centered">
										<div class="modal-content myinvoices_modal-content">
											<div class="modal-body p-4">
												<span class="menutitle">Hóa đơn #${invoices.id}</span>
												${modalstatus}
												<h6 class="" id="" style="">Ngày viết hóa đơn: ${invoices.sent_date}</h6>
												${limit_pay_date}
												<h6 class="" id="" style="margin-top: 20px;">Người nhận: ${invoices.receiver_name}</h6>
												<h6 class="" id="" style="">Người gửi: ${invoices.author_name}</h6>
												<hr>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px;">${invoices.item}</span> <span class="" id="" style="font-size: 18px;">${Math.round(invoices.invoice_value - Math.round(invoices.invoice_value * (event.data.VAT/100))).toLocaleString()} 💵</span>
												</div>
												<hr>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px; font-weight: 700;">Tổng phụ</span> <span class="" id="" style="font-size: 18px;">${Math.round(invoices.invoice_value - Math.round(invoices.invoice_value * (event.data.VAT/100))).toLocaleString()} 💵</span>
												</div>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px; font-weight: 700;">VAT (${event.data.VAT}%)</span> <span class="" id="" style="font-size: 18px;">${Math.round(invoices.invoice_value * (event.data.VAT/100)).toLocaleString()} 💵</span>
												</div>
												<br>
												<div class="d-flex justify-content-between">
													<span class="" id="" style="color: #e6e6e6; font-size: 20px; font-weight: 700;">Toàn bộ</span> <span class="" id="" style="font-size: 18px;">${Math.round(invoices.invoice_value).toLocaleString()} 💵</span>
												</div>
												<br>
												<div class="d-flex justify-content-center">
													${payment_status}
												</div>
												<br>
											</div>
										</div>
									</div>
								</div>
								`;
					$("body").append(modal);
				}
			$("#societyInvoicesData").html(row);

			// Always show the window first
			if (!$(".societyinvoices").is(':visible')) {
				$(".societyinvoices").fadeIn();
			}

			// Don't use DataTable when pagination is active to avoid layout conflicts
			if (event.data.totalPages <= 1 && event.data.invoices.length > 0) {
				// Only initialize DataTable for single page datasets
				setTimeout(function() {
					const societyinvoices = document.getElementById('societyInvoices');
					if (societyinvoices && !societyinvoices.classList.contains('dataTable-table')) {
						table.push(new simpleDatatables.DataTable(societyinvoices, {
							searchable: true,
							perPageSelect: false,
							perPage: 5,
						}));
					}
				}, 100);
			}
			
			break
	}
});

// Button Actions
$(document).on('click', ".showInvoice", function() {
	var modalId = $(this).attr('data-target');
	var invoiceModal = new bootstrap.Modal(modalId);
	invoiceModal.show()
});

$(document).on('click', ".payInvoice", function() {
	var invoiceId = $(this).attr('data-invoiceId');

	$.post('https://okokBilling/action', JSON.stringify ({
		action: "payInvoice",
		invoice_id: invoiceId,
	}));

	$(".myinvoices").fadeOut();

	setTimeout(function(){
		windowIsOpened = false

		for(var i=0; i<table.length; i++) {
			table[i].destroy();
			table.splice(i, 1);
		}

		$(".modal").remove();
	}, 400);
});

$(document).on('click', ".cancelInvoice", function() {
	var invoiceId = $(this).attr('data-invoiceId');

	$.post('https://okokBilling/action', JSON.stringify ({
		action: "cancelInvoice",
		invoice_id: invoiceId,
	}));

	$(".societyinvoices").fadeOut();

	setTimeout(function(){
		windowIsOpened = false

		for(var i=0; i<table.length; i++) {
			table[i].destroy();
			table.splice(i, 1);
		}

		$(".modal").remove();
	}, 400);
});

$(document).on('click', '#menuMyInvoices', function() {
	windowIsOpened = false
	$(".mainmenu").fadeOut();
	
	// Reset về trang 1 để load hóa đơn mới nhất
	myInvoicesCurrentPage = 1;

	$.post('http://okokBilling/action', JSON.stringify ({
		action: "mainMenuOpenMyInvoices",
		page: 1
	}));
})

$(document).on('click', '#menuSocietyInvoices', function() {
	windowIsOpened = false
	$(".mainmenu").fadeOut();
	
	// Reset về trang 1 để load hóa đơn mới nhất
	societyCurrentPage = 1;

	$.post('http://okokBilling/action', JSON.stringify ({
		action: "mainMenuOpenSocietyInvoices",
		page: 1
	}));
})

$(document).on('click', '#menuCreateInvoice', function() {
	windowIsOpened = false
	$(".mainmenu").fadeOut();

	$.post('http://okokBilling/action', JSON.stringify ({
		action: "mainMenuOpenCreateInvoice"
	}));
})

$(document).on('click', '#sendInvoice', function() {
	var invoice_value = $("#invoice_value").val();
	var invoice_item = $("#invoice_item").val();
	var invoice_notes = $("#invoice_notes").val();

	if (document.getElementById("invoice_notes").value === "") {
		invoice_notes = "Nothing to add.";
	}

	if(!invoice_value || !invoice_item) {
		$.post('http://okokBilling/action', JSON.stringify({
			action: "missingInfo",
		}));
	} else {
		if(invoice_value <= 0) {
			$.post('http://okokBilling/action', JSON.stringify({
				action: "negativeAmount",
			}));
		} else if(invoice_value > 500000) {
			$.post('http://okokBilling/action', JSON.stringify({
				action: "exceedLimit",
			}));
		} else {
			// Lưu thông tin vào localStorage trước khi gửi
			var invoiceData = {
				item: invoice_item,
				value: invoice_value,
				notes: invoice_notes
			};
			localStorage.setItem('lastInvoiceData', JSON.stringify(invoiceData));
			
			$(".sendinvoice").fadeOut();
			windowIsOpened = false

			$.post('http://okokBilling/action', JSON.stringify({
				action: "createInvoice",
				target: 0,
				targetName: -1,
				society: "",
				society_name: "",
				invoice_value: invoice_value,
				invoice_item: invoice_item,
				invoice_notes: "Ghi chú: " + invoice_notes
			}));

			setTimeout(function() {
				for(var i=0; i<table.length; i++) {
					table[i].destroy();
					table.splice(i, 1);
				}
				$("#invoice_value").val("");
				$("#invoice_item").val("");
				$("#invoice_notes").val("");
			}, 400);
		}
	}
})

$(document).on('click', "#closeMainMenu", function() {
	var popuprev = new Audio('popupreverse.mp3');
	popuprev.volume = 0.4;
	popuprev.play();

	windowIsOpened = false
	$(".mainmenu").fadeOut();

	$.post('https://okokBilling/action', JSON.stringify({
		action: "close",
	}));
});

$(document).on('click', "#closeSendInvoice", function() {
	var popuprev = new Audio('popupreverse.mp3');
	popuprev.volume = 0.4;
	popuprev.play();

	$(".sendinvoice").fadeOut();

	setTimeout(function() {
		windowIsOpened = false

		for(var i=0; i<table.length; i++) {
			table[i].destroy();
			table.splice(i, 1);
		}

		$("#invoice_value").val("");
		$("#invoice_item").val("");
		$("#invoice_notes").val("");
		$(".modal").remove();
	}, 400);

	$.post('https://okokBilling/action', JSON.stringify({
		action: "close",
	}));
});

$(document).on('click', "#closeSocietyInvoices", function() {
	var popuprev = new Audio('popupreverse.mp3');
	popuprev.volume = 0.4;
	popuprev.play();

	$(".societyinvoices").fadeOut();

	setTimeout(function() {
		windowIsOpened = false

		for(var i=0; i<table.length; i++) {
			table[i].destroy();
			table.splice(i, 1);
		}

		$(".modal").remove();
	}, 400);

	$.post('https://okokBilling/action', JSON.stringify({
		action: "close",
	}));
});

$(document).on('click', "#closeMyInvoices", function() {
	var popuprev = new Audio('popupreverse.mp3');
	popuprev.volume = 0.4;
	popuprev.play();

	$(".myinvoices").fadeOut();

	setTimeout(function() {
		windowIsOpened = false

		for(var i=0; i<table.length; i++) {
			table[i].destroy();
			table.splice(i, 1);
		}

		$(".modal").remove();
	}, 400);

	$.post('https://okokBilling/action', JSON.stringify({
		action: "close",
	}));
});

// Close ESC Key
$(document).ready(function() {
	document.onkeyup = function(data) {
		if (data.which == 27) {
			var popuprev = new Audio('popupreverse.mp3');
			popuprev.volume = 0.4;
			popuprev.play();
			switch (selectedWindow) {
				case 'myinvoices':
					$(".myinvoices").fadeOut();

					setTimeout(function() {
						windowIsOpened = false

						for(var i=0; i<table.length; i++) {
							table[i].destroy();
							table.splice(i, 1);
						}

						$(".modal").remove();
					}, 400);

					$.post('https://okokBilling/action', JSON.stringify({
						action: "close",
					}));
					break
				case 'mainMenu':
					windowIsOpened = false

					$(".mainmenu").fadeOut();

					$.post('https://okokBilling/action', JSON.stringify({
						action: "close",
					}));
					break
				case 'societyinvoices':
					$(".societyinvoices").fadeOut();

				    setTimeout(function() {
						windowIsOpened = false

						for(var i=0; i<table.length; i++) {
							table[i].destroy();
							table.splice(i, 1);
						}

						$(".modal").remove();
					}, 400);

				    $.post('https://okokBilling/action', JSON.stringify({
				        action: "close",
				    }));
					break
				case 'createinvoice':
					$(".sendinvoice").fadeOut();

					setTimeout(function() {
						windowIsOpened = false

						for(var i=0; i<table.length; i++) {
							table[i].destroy();
							table.splice(i, 1);
						}

						$(".modal").remove();
					}, 400);

					$.post('https://okokBilling/action', JSON.stringify({
						action: "close",
					}));
					break
			}
		}
	};
});

// Pagination event handlers for Society Invoices
$(document).on('click', '#prevPage', function() {
	if (!$(this).hasClass('disabled') && societyCurrentPage > 1) {
		$(".societyinvoices").fadeOut();
		
		setTimeout(function(){
			windowIsOpened = false;
			
			for(var i=0; i<table.length; i++) {
				table[i].destroy();
				table.splice(i, 1);
			}
			
			$(".modal").remove();
			
			// Request previous page
			$.post('https://okokBilling/action', JSON.stringify({
				action: "mainMenuOpenSocietyInvoices",
				page: societyCurrentPage - 1
			}));
		}, 400);
	}
});

$(document).on('click', '#nextPage', function() {
	if (!$(this).hasClass('disabled')) {
		$(".societyinvoices").fadeOut();
		
		setTimeout(function(){
			windowIsOpened = false;
			
			for(var i=0; i<table.length; i++) {
				table[i].destroy();
				table.splice(i, 1);
			}
			
			$(".modal").remove();
			
			// Request next page
			$.post('https://okokBilling/action', JSON.stringify({
				action: "mainMenuOpenSocietyInvoices",
				page: societyCurrentPage + 1
			}));
		}, 400);
	}
});

// Pagination event handlers for My Invoices
$(document).on('click', '#myInvoicesPrevPage', function() {
	if (!$(this).hasClass('disabled') && myInvoicesCurrentPage > 1) {
		$(".myinvoices").fadeOut();
		
		setTimeout(function(){
			windowIsOpened = false;
			
			for(var i=0; i<table.length; i++) {
				table[i].destroy();
				table.splice(i, 1);
			}
			
			$(".modal").remove();
			
			// Request previous page
			$.post('https://okokBilling/action', JSON.stringify({
				action: "mainMenuOpenMyInvoices",
				page: myInvoicesCurrentPage - 1
			}));
		}, 400);
	}
});

$(document).on('click', '#myInvoicesNextPage', function() {
	if (!$(this).hasClass('disabled')) {
		$(".myinvoices").fadeOut();
		
		setTimeout(function(){
			windowIsOpened = false;
			
			for(var i=0; i<table.length; i++) {
				table[i].destroy();
				table.splice(i, 1);
			}
			
			$(".modal").remove();
			
			// Request next page
			$.post('https://okokBilling/action', JSON.stringify({
				action: "mainMenuOpenMyInvoices",
				page: myInvoicesCurrentPage + 1
			}));
		}, 400);
	}
});