(() => {
  const params = new URLSearchParams(window.location.search);
  const result = params.get('result') === 'success' ? 'success' : 'cancel';
  const contractId = Number.parseInt(params.get('contract_id') || '', 10);
  const validContractId = Number.isSafeInteger(contractId) && contractId > 0;
  const query = new URLSearchParams({ result });
  if (validContractId) query.set('contract_id', String(contractId));
  const deepLink = `launchpad://payment-return/?${query.toString()}`;

  const title = document.getElementById('title');
  const message = document.getElementById('message');
  const status = document.getElementById('status');
  const openApp = document.getElementById('open-app');
  const eyebrow = document.getElementById('eyebrow');

  openApp.href = deepLink;
  if (result === 'success') {
    eyebrow.textContent = 'Checkout complete';
    title.textContent = 'Payment received.';
    message.textContent = 'Return to your project to verify the transaction and continue the contract.';
    status.textContent = 'Opening the payment receipt';
  } else {
    eyebrow.textContent = 'Checkout closed';
    title.textContent = 'Payment was not completed.';
    message.textContent = 'Return to the project when you are ready to restart the test checkout.';
    status.textContent = 'Returning to your project';
  }

  window.setTimeout(() => window.location.assign(deepLink), 650);
})();
