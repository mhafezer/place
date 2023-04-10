<script>
    import { onMount } from 'svelte';
    import { Auth } from '../../aws'
    import { user } from '../../stores'

    onMount(async () => {
        try {
            await Auth.signOut()
        } catch {

        }

    })

    async function signUp(email, password) {
        try {
            $user = await Auth.signUp({
                username: email,
                password,
                autoSignIn: {
                    enabled: true,
                },
            });
            console.log($user);
            window.location.href = '/signin'
        } catch (error) {
            console.log('error signing up:', error);
        }
    }

    async function submit(event) {
        let formData = new FormData(event.target)
        await signUp(formData.get('email'), formData.get('password'))
    }
</script>

<div class="flex flex-col items-center justify-center absolute inset-0 bg-neutral-700">
    <form class="flex flex-col" on:submit={submit}>
        <input type='email' name='email' placeholder="email" class="rounded-md m-1 p-2"/>
        <input type='password' name='password' placeholder="password" class="rounded-md m-1 p-2"/>
        <button type="submit" class="bg-teal-400 hover:bg-teal-600 rounded-md m-1 p-1" >sign up!</button>
    </form>
</div>
