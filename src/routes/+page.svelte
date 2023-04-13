
<script>
    import {API, Auth} from '../aws'
    import { onMount } from "svelte";
    import Panzoom from 'panzoom'
    import { GRAPHQL_AUTH_MODE } from '@aws-amplify/auth';
    import { user } from '../stores'
    
    let subscribeUpdatesDoc = `
        subscription pixelUpdates {
            updatedPixel {
                color
                x
                y
            }
        }
    `
    let colors = ['FloralWhite', 'SlateGray', 'LightSkyBlue', 'LightPink', 'LightSeaGreen', 'LightGreen', 'LightSalmon', 'LightCoral', 'khaki', 'Chocolate'];
    let currentColor = 0;
    let canvas;
    let ctx;
    let canvasParent;
    let x = 0;
    let y = 0;  

    let time = 0

    onMount(async () => {
        // canvas setup
        Panzoom(canvas, {
            initialZoom: 0.15,
            initialX: 2000,
            initialY: 2000,
            onClick: (event) => {
                sendUpdateRequest()
            }
        })
      
        ctx = canvas.getContext("2d", {
            antialias: false,
            alpha: false,
            desynchronized: true,
        })
        ctx.fillStyle = "rgb(45,212,191)"
        ctx.fillRect(0, 0, 1000, 1000)

        for (let chunk = 0; chunk < 25; chunk++) {
            API.graphql({
                query: 
                    `query listPlaceChunks {
                        getPlaceChunks(c: "${chunk}") {
                            c
                            v
                        }
                    }`
            }).then((value) => {
                let c = value.data.getPlaceChunks.c
                let v = value.data.getPlaceChunks.v
                for (let i = 0; i < 40000; i++) {
                    let index = c * 40000 + i
                    let y = Math.floor(index / 1000)
                    let x = index - (y * 1000)
                    ctx.fillStyle = colors[v[i]]
                    ctx.fillRect(x, y, 1, 1)
                }
            })
        }
        
        // subscribing to appsync updates
        const sub = API.graphql({query: subscribeUpdatesDoc}).subscribe({
            next: ({provider, value}) => {
                let updatedPixel = value.data.updatedPixel
                updatePixel(updatedPixel.x, updatedPixel.y, updatedPixel.color)
            } 
        })

        // checking if user is signed in
        Auth.currentAuthenticatedUser()
            .then((value) => {
                $user = value;
                console.log($user)
            })
            .catch(console.log)

        return () => sub.unsubscribe()
    })

    function sendUpdateRequest() {
        if (time > 0) {
            alert("please wait for countdown to finish")
            return
        }
        time = 11
        const interval = setInterval(() => {
            if (time <= 0) {
                clearInterval(interval)
            } else {
                time = time - 1
            }
        }, 1000)
        Auth.currentAuthenticatedUser()
            .then((user) => {
                let config = {
                    headers: {
                        Authorization: user.signInUserSession.idToken.jwtToken
                    }
                }
                API.graphql({
                    query: `
                        mutation MyMutation {
                            updateBoard(color: ${currentColor}, x: ${x}, y: ${y}) {
                                color
                                x
                                y
                            }
                        }
                        `,
                    authMode: GRAPHQL_AUTH_MODE.AMAZON_COGNITO_USER_POOLS,
                }, config).catch(console.log)
                updatePixel(x, y, currentColor)
            }
            ).catch(() => {
                alert(`Must be logged in to update the board!`)
                clearInterval(interval)
                time = 0
            })
    }

    function getRelativeCoords(event) {
        x = Math.floor(event.offsetX / 4)
        y = Math.floor(event.offsetY / 4)
    }

    function updatePixel(x, y, color) {
        console.log(`updated pixel (${x}, ${y}) with color ${colors[color]}`)
        ctx.fillStyle = colors[color]
        ctx.fillRect(x, y, 1,1)
    }
</script>
 

<div class="flex flex-col justify-between  absolute inset-0 bg-neutral-700 overflow-hidden">
    <div class="z-10 flex flex-col items-center pointer-events-none">
        <h1 class="font-bold text-4xl p-2 rounded-md m-2 bg-neutral-700 text-stone-100 select-none cursor-default">eslamira<span class="text-teal-400">place</span></h1>
        <div class=" text-center bg-neutral-700 rounded-3xl px-5">
            <h1 class="text-stone-100">mouse: ({x},{y}) color: <span style="background-color: {colors[currentColor]};">&#8203 &#8203 &#8203 &#8203 &#8203 </span></h1>
        </div>
        {#if time}
            <h1 class="text-stone-100 bg-red-800 text-red-200 bg rounded-3xl px-2 m-2">request countdown: {time}</h1>
        {/if}
    </div>
    <div class="flex flex-col z-10 items-center">
        <div class="m-1 p-1 text-center bg-neutral-700 rounded-3xl border border-stone-100">
            {#if $user}
                <h1 class="text-stone-100">user: {$user.attributes.email}</h1>
            {:else}
                <a href="signin" class="text-stone-100 hover:text-neutral-400 p-1">signin</a>
            {/if}
        </div>
        <div class="flex rounded-md p-2 bg-neutral-700 m-2">
            {#each colors as color, index}
                <div on:click={() => currentColor = index} class="m-1">
                    <input id={index} type="radio" name="colors" class="hidden peer"/>
                    <label for={index} class="rounded-lg p-1 cursor-pointer peer-checked:border-teal-400 peer-checked:border-4 text-black text-opacity-0" style="background-color: {color}"> 
                        ....
                    </label>
                </div>
            {/each}
        </div>
    </div>
</div>
<div class="flex items-center justify-center fixed inset-0 h-full w-full" >
    <div bind:this={canvasParent}>
        <canvas width={1000} height={1000} bind:this={canvas} on:pointerdown={getRelativeCoords} on:pointermove={getRelativeCoords} class="h-4/6"/>
    </div>
</div>


<style lang="postcss">
    canvas {
        width: 4000px;
        height: 4000px;
        image-rendering: crisp-edges;
        image-rendering: pixelated;
    }
</style>