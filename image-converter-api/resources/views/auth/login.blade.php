<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" class="h-full">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ __('Log in') }} - {{ config('app.name', 'Laravel') }}</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=instrument-sans:400,500,600,700" rel="stylesheet" />

    <!-- Styles / Scripts -->
    @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @else
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'media',
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Instrument Sans', 'ui-sans-serif', 'system-ui', 'sans-serif'],
                    },
                    colors: {
                        primary: {
                            50: '#fff1f2',
                            100: '#ffe4e6',
                            200: '#fecdd3',
                            300: '#fda4af',
                            400: '#fb7185',
                            500: '#f43f5e', // Rose-500 equivalent as base
                            600: '#e11d48',
                            700: '#be123c',
                            800: '#9f1239',
                            900: '#881337',
                        }
                    }
                },
            },
        }
    </script>
    @endif
</head>

<body class="h-full bg-[#FDFDFC] dark:bg-[#0a0a0a] font-sans antialiased text-[#1b1b18] dark:text-[#EDEDEC] transition-colors duration-300">

    <div class="flex min-h-full flex-col justify-center py-12 sm:px-6 lg:px-8 relative overflow-hidden">

        <!-- Background Elements -->
        <div class="absolute inset-0 w-full h-full">
            <div class="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-[#FF2D20]/10 blur-[100px] opacity-70 animate-pulse"></div>
            <div class="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-purple-500/10 blur-[100px] opacity-70 animate-pulse" style="animation-duration: 4s;"></div>
        </div>

        <div class="sm:mx-auto sm:w-full sm:max-w-md relative z-10">
            <!-- Logo -->
            <div class="flex justify-center">
                <svg class="h-12 w-auto text-[#FF2D20]" viewBox="0 0 62 65" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M61.8548 14.6253C61.8778 14.7102 61.8895 14.7978 61.8895 14.8858V28.5615C61.8895 28.7392 61.8444 28.9132 61.7589 29.0665C61.3854 29.7391 60.8924 30.3444 60.2917 30.8647C59.0305 31.8105 57.5101 32.3242 55.9392 32.3242C52.0163 32.3242 48.8251 30.2922 47.1691 27.2002C45.3529 23.8241 45.3529 19.8258 47.1691 16.4497C48.8251 13.3577 52.0163 11.3257 55.9392 11.3257C57.5101 11.3257 59.0305 11.8394 60.2917 12.7852C60.8924 13.3055 61.3854 13.9108 61.7589 14.5834C61.8444 14.7367 61.8895 14.9107 61.8895 15.0884V14.6253H61.8548Z" fill="currentColor" />
                    <path d="M47.1691 16.4497C45.3529 19.8258 45.3529 23.8241 47.1691 27.2002C48.8251 30.2922 52.0163 32.3242 55.9392 32.3242C57.5101 32.3242 59.0305 31.8105 60.2917 30.8647V52.171C60.2917 56.5585 56.4055 60.0392 51.6811 60.0392C46.9567 60.0392 43.125 56.46 43.125 52.0725L43.125 24.3168C43.125 10.9823 33.4721 0.170898 21.5625 0.170898C9.65287 0.170898 0 10.9823 0 24.3168V53.2543C0 57.6418 3.8863 61.1225 8.61066 61.1225C13.335 61.1225 17.1667 57.6418 17.1667 53.2543V24.3168C17.1667 19.9293 19.1415 15.7537 21.5625 14.3323C23.9835 12.9109 25.9583 14.5332 25.9583 18.9207V52.0725C25.9583 61.464 33.1593 68.665 43.125 68.665C53.0907 68.665 60.2917 61.464 60.2917 52.0725V30.8647C60.8924 30.3444 61.3854 29.7391 61.7589 29.0665C61.8444 28.9132 61.8895 28.7392 61.8895 28.5615V15.0884C61.8895 14.9107 61.8444 14.7367 61.7589 14.5834C61.3854 13.9108 60.8924 13.3055 60.2917 12.7852C59.0305 11.8394 57.5101 11.3257 55.9392 11.3257C52.0163 11.3257 48.8251 13.3577 47.1691 16.4497Z" fill="currentColor" />
                </svg>
            </div>

            <h2 class="mt-6 text-center text-3xl font-semibold tracking-tight text-[#1b1b18] dark:text-white">
                Sign in to your account
            </h2>
            <p class="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
                Or
                <a href="#" class="font-medium text-[#FF2D20] hover:text-[#d92419] transition-colors duration-200">
                    start your 14-day free trial
                </a>
            </p>
        </div>

        <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-[480px] relative z-10">
            <div class="bg-white/80 dark:bg-[#161615]/80 backdrop-blur-xl px-6 py-12 shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-[0_8px_30px_rgb(0,0,0,0.2)] sm:rounded-2xl sm:px-12 border border-white/20 dark:border-[#3E3E3A]">
                <form class="space-y-6" action="#" method="POST">
                    @csrf

                    <div>
                        <label for="email" class="block text-sm font-medium leading-6 text-[#1b1b18] dark:text-[#EDEDEC]">Email address</label>
                        <div class="mt-2 relative">
                            <input id="email" name="email" type="email" autocomplete="email" required
                                class="block w-full rounded-xl border-0 py-3 text-[#1b1b18] dark:text-white shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-[#3E3E3A] placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-[#FF2D20] sm:text-sm sm:leading-6 bg-white/50 dark:bg-[#0a0a0a]/50 transition-all duration-200 ease-in-out">
                        </div>
                    </div>

                    <div>
                        <label for="password" class="block text-sm font-medium leading-6 text-[#1b1b18] dark:text-[#EDEDEC]">Password</label>
                        <div class="mt-2 relative">
                            <input id="password" name="password" type="password" autocomplete="current-password" required
                                class="block w-full rounded-xl border-0 py-3 text-[#1b1b18] dark:text-white shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-[#3E3E3A] placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-[#FF2D20] sm:text-sm sm:leading-6 bg-white/50 dark:bg-[#0a0a0a]/50 transition-all duration-200 ease-in-out">
                        </div>
                    </div>

                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <input id="remember-me" name="remember-me" type="checkbox" class="h-4 w-4 rounded border-gray-300 dark:border-[#3E3E3A] text-[#FF2D20] focus:ring-[#FF2D20] bg-transparent">
                            <label for="remember-me" class="ml-3 block text-sm leading-6 text-gray-700 dark:text-gray-300">Remember me</label>
                        </div>

                        <div class="text-sm leading-6">
                            <a href="#" class="font-medium text-[#FF2D20] hover:text-[#d92419] transition-colors duration-200">Forgot password?</a>
                        </div>
                    </div>

                    <div>
                        <button type="submit"
                            class="flex w-full justify-center rounded-xl bg-[#FF2D20] px-3 py-3 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-[#d92419] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#FF2D20] transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98]">
                            Sign in
                        </button>
                    </div>
                </form>

                <div>
                    <div class="relative mt-10">
                        <div class="absolute inset-0 flex items-center" aria-hidden="true">
                            <div class="w-full border-t border-gray-200 dark:border-[#3E3E3A]"></div>
                        </div>
                        <div class="relative flex justify-center text-sm font-medium leading-6">
                            <span class="bg-white dark:bg-[#161615] px-6 text-gray-500 dark:text-gray-400">Or continue with</span>
                        </div>
                    </div>

                    <div class="mt-6 grid grid-cols-2 gap-4">
                        <a href="#" class="flex w-full items-center justify-center gap-3 rounded-xl bg-white dark:bg-[#161615] px-3 py-3 text-sm font-semibold text-[#1b1b18] dark:text-[#EDEDEC] shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-[#3E3E3A] hover:bg-gray-50 dark:hover:bg-[#1E1E1D] focus-visible:ring-transparent transition-all duration-200">
                            <svg class="h-5 w-5" aria-hidden="true" viewBox="0 0 24 24">
                                <path d="M12.0003 20.4144C16.6493 20.4144 20.4147 16.649 20.4147 12C20.4147 7.35102 16.6493 3.58557 12.0003 3.58557C7.35129 3.58557 3.58594 7.35102 3.58594 12C3.58594 16.649 7.35129 20.4144 12.0003 20.4144Z" fill="currentColor" fill-opacity="0" />
                                <path d="M20.1504 12.0986C20.1504 11.4587 20.0934 10.9231 19.9868 10.3306H11.9678V13.5132H16.6393C16.4897 14.524 15.9344 15.8231 14.8517 16.5921L14.8339 16.696L17.3653 18.658L17.5408 18.6754C19.1136 17.2268 20.1504 14.9818 20.1504 12.0986Z" fill="#4285F4" />
                                <path d="M11.9678 20.505C14.269 20.505 16.1979 19.7423 17.6116 18.435L14.8517 16.2929C14.0617 16.8284 13.0649 17.0736 11.9678 17.0736C9.72584 17.0736 7.82522 15.5492 7.14187 13.4925L7.04231 13.5009L4.41031 15.5367L4.37646 15.636C5.78601 18.4419 8.65778 20.505 11.9678 20.505Z" fill="#34A853" />
                                <path d="M7.14183 13.4924C6.96387 12.9569 6.86419 12.3861 6.86419 11.7979C6.86419 11.2096 6.96387 10.6388 7.14183 10.1034L7.1367 9.99187L4.48425 7.93481L4.37643 7.98592C3.78564 9.16335 3.45107 10.4367 3.45107 11.7979C3.45107 13.1591 3.78564 14.4324 4.37643 15.6099L7.14183 13.4924Z" fill="#FBBC05" />
                                <path d="M11.9678 6.52205C13.5641 6.52205 14.6808 7.21178 15.293 7.79455L17.7255 5.41604C16.1908 3.98894 14.269 3.10669 11.9678 3.10669C8.65778 3.10669 5.78601 5.16979 4.37646 7.98592L7.14183 10.1034C7.82522 8.04675 9.72584 6.52205 11.9678 6.52205Z" fill="#EB4335" />
                            </svg>
                            <span class="text-sm font-semibold leading-6">Google</span>
                        </a>

                        <a href="#" class="flex w-full items-center justify-center gap-3 rounded-xl bg-white dark:bg-[#161615] px-3 py-3 text-sm font-semibold text-[#1b1b18] dark:text-[#EDEDEC] shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-[#3E3E3A] hover:bg-gray-50 dark:hover:bg-[#1E1E1D] focus-visible:ring-transparent transition-all duration-200">
                            <svg class="h-5 w-5 text-[#1b1b18] dark:text-white" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                <path fill-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clip-rule="evenodd" />
                            </svg>
                            <span class="text-sm font-semibold leading-6">GitHub</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>

</body>

</html>