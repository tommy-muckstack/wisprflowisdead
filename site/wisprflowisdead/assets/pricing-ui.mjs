import {referencePrices, estimateTimeValue} from './pricing.mjs';
const $ = id => document.getElementById(id);
const compact = matchMedia('(max-width:900px)');
const billingButtons = [...document.querySelectorAll('[data-billing]')];
let period = 'annual';
function updatePrices(announce = true) {
  const prices = referencePrices(period, $('notetaker-addon').checked);
  document.querySelectorAll('[data-price]').forEach(node => {node.textContent = '$' + prices[node.dataset.price];});
  billingButtons.forEach(button => {
    const active = button.dataset.billing === period;
    button.classList.toggle('on', active);
    button.setAttribute('aria-pressed', String(active));
  });
  document.querySelectorAll('[data-billing-note]').forEach(node => {
    node.textContent = `Billed ${period === 'annual' ? 'yearly' : 'monthly'} · Wispr Flow reference`;
  });
  $('reference-note').firstChild.textContent = `Reference prices in USD, checked 15 October 2026. ${period === 'annual' ? 'Annual prices are per month, billed yearly.' : 'Monthly prices are billed monthly.'} `;
  if (announce) $('billing-status').textContent = `Wispr Flow reference: Pro $${prices.pro}, Growth $${prices.growth} per user per month, billed ${period === 'annual' ? 'yearly' : 'monthly'}. WisprFlowIsDead remains free.`;
}
billingButtons.forEach(button => {
  button.disabled = false;
  button.addEventListener('click', () => {period = button.dataset.billing; updatePrices();});
});
$('notetaker-addon').disabled = false;
$('notetaker-addon').addEventListener('change', () => updatePrices());
updatePrices(false);

const disclosures = [...document.querySelectorAll('.seeall')];
const expandedCards = new Set();
function updateCard(button, index) {
  const expanded = !compact.matches || expandedCards.has(index);
  button.closest('.pcard2').classList.toggle('open', expanded);
  button.setAttribute('aria-expanded', String(expanded));
  button.querySelector('span').textContent = expanded ? 'Hide all features' : 'See all features';
  $(button.getAttribute('aria-controls')).hidden = !expanded;
  if (!compact.matches && document.activeElement === button) button.closest('.pcard2').querySelector('.pbtn').focus();
}
disclosures.forEach((button, index) => {
  button.addEventListener('click', () => {
    if (expandedCards.has(index)) expandedCards.delete(index); else expandedCards.add(index);
    updateCard(button, index);
  });
});

const questions = [...document.querySelectorAll('.fq')];
const answers = questions.map((_, i) => $('answer-' + i));
let selectedQuestion = compact.matches ? -1 : 0;
function showQuestion(index, toggle = false) {
  selectedQuestion = compact.matches && toggle && selectedQuestion === index ? -1 : index;
  updateFAQ();
}
function updateFAQ() {
  const mobile = compact.matches;
  if (!mobile && selectedQuestion < 0) selectedQuestion = 0;
  const list = $('faq-controls');
  if (mobile) {
    list.removeAttribute('role'); list.removeAttribute('aria-orientation'); list.removeAttribute('aria-label');
  } else {
    list.setAttribute('role', 'tablist'); list.setAttribute('aria-orientation', 'vertical'); list.setAttribute('aria-label', 'Pricing questions');
  }
  questions.forEach((button, index) => {
    const active = index === selectedQuestion;
    button.disabled = false;
    button.classList.toggle('on', active);
    button.tabIndex = mobile || active ? 0 : -1;
    button.setAttribute('aria-controls', mobile ? answers[index].id : 'faq-answer');
    if (mobile) {
      button.removeAttribute('role'); button.removeAttribute('aria-selected');
      button.setAttribute('aria-expanded', String(active));
      button.parentElement.removeAttribute('role');
    } else {
      button.setAttribute('role', 'tab'); button.setAttribute('aria-selected', String(active));
      button.removeAttribute('aria-expanded'); button.parentElement.setAttribute('role', 'presentation');
    }
    answers[index].hidden = !mobile || !active;
  });
  const panel = $('faq-answer');
  const panelWasFocused = document.activeElement === panel;
  panel.hidden = mobile;
  if (!mobile) {
    panel.setAttribute('role', 'tabpanel'); panel.tabIndex = 0;
    panel.setAttribute('aria-labelledby', questions[selectedQuestion].id);
    $('fqq').textContent = questions[selectedQuestion].textContent;
    $('fbub').textContent = answers[selectedQuestion].textContent;
  }
  // Keep focus usable when the desktop answer panel disappears on resize.
  if (mobile && panelWasFocused) questions[Math.max(0, selectedQuestion)].focus();
}
questions.forEach((button, index) => {
  button.addEventListener('click', () => showQuestion(index, true));
  button.addEventListener('keydown', event => {
    if (compact.matches) return;
    const next = {ArrowDown:(index + 1) % questions.length, ArrowUp:(index + questions.length - 1) % questions.length, Home:0, End:questions.length - 1}[event.key];
    if (next === undefined) return;
    event.preventDefault(); showQuestion(next); questions[next].focus();
  });
});
function layout() {
  const focusedQuestion = questions.indexOf(document.activeElement);
  if (!compact.matches && focusedQuestion >= 0) selectedQuestion = focusedQuestion;
  disclosures.forEach(updateCard);
  updateFAQ();
}
compact.addEventListener('change', layout);
layout();

const hours = $('roiH'), rate = $('roiR');
const number = new Intl.NumberFormat('en-US', {maximumFractionDigits:1});
const money = new Intl.NumberFormat('en-US', {style:'currency', currency:'USD', maximumFractionDigits:0});
function calculate() {
  const result = estimateTimeValue(hours.value, rate.value);
  const invalid = Object.keys(result.errors).length > 0;
  hours.setAttribute('aria-invalid', String(Boolean(result.errors.hours)));
  rate.setAttribute('aria-invalid', String(Boolean(result.errors.rate)));
  $('roi-error').textContent = Object.values(result.errors).join(' ');
  $('roiT').textContent = invalid ? '—' : `${number.format(result.monthlyHours)} ${result.monthlyHours === 1 ? 'hour' : 'hours'}`;
  $('roiS').textContent = invalid ? '—' : money.format(result.annualValue);
}
[hours, rate].forEach(input => {input.disabled = false; input.addEventListener('input', calculate);});
calculate();
document.body.classList.add('pricing-enhanced');
