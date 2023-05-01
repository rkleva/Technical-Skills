function toggleMenu(displayState){
    const nav = document.getElementById('header_navigation');
    const close_ico =document.getElementById('close-ico');

    nav.style.display = displayState;
    close_ico.style.display = displayState;
}